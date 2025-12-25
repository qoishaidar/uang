import Foundation
import SwiftUI
import Combine
import Supabase

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    let client = SupabaseClient(
        supabaseURL: URL(string: Config.supabaseUrl)!,
        supabaseKey: Config.supabaseKey,
        options: SupabaseClientOptions(
            auth: .init(storage: NoOpAuthLocalStorage(), autoRefreshToken: false, emitLocalSessionAsInitialSession: true)
        )
    )
    
    @Published var transactions: [Transaction] = []
    @Published var wallets: [Wallet] = []
    @Published var assets: [Asset] = []
    @Published var categories: [Category] = []
    @Published var isAmountHidden: Bool = false
    @Published var totalBalance: Double = 0
    @Published var totalIncome: Double = 0
    @Published var totalExpense: Double = 0
    
    private let cacheFileName = "data_cache.json"
    private var cacheFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(cacheFileName)
    }
    
    init() {
        loadFromCache()
        Task {
            await fetchData()
        }
    }
    
    private func loadFromCache() {
        guard let url = cacheFileURL, let data = try? Data(contentsOf: url) else { return }
        do {
            let cache = try JSONDecoder().decode(CacheData.self, from: data)
            self.transactions = cache.transactions
            self.wallets = cache.wallets
            self.assets = cache.assets
            self.categories = cache.categories
            calculateTotals()
        } catch {
            print("Error loading from cache: \(error)")
        }
    }
    
    private func saveToCache() {
        guard let url = cacheFileURL else { return }
        let cache = CacheData(transactions: transactions, wallets: wallets, assets: assets, categories: categories)
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: url)
        } catch {
            print("Error saving to cache: \(error)")
        }
    }
    
    private let pendingSortKey = "hasPendingCategorySort"
    
    @MainActor
    func fetchData() async {
        do {
            let fetchedCategories: [Category] = try await client.from("categories").select().order("sort_order", ascending: true).execute().value
            
            if UserDefaults.standard.bool(forKey: pendingSortKey) {
                print("Found pending sort updates. Preserving local order and syncing.")
                // Merge strategy: Keep local order, update content (e.g. names/icons) from server
                // 1. Create lookup for fetched items
                let fetchedMap = Dictionary(uniqueKeysWithValues: fetchedCategories.map { ($0.id, $0) })
                
                // 2. Reconstruct list based on local cache order
                var mergedCategories: [Category] = []
                var localIds = Set<String>()
                
                // Keep local items that still exist on server, updating their content
                for localCat in self.categories {
                    if let serverCat = fetchedMap[localCat.id] {
                        var updatedCat = serverCat
                        updatedCat.sortOrder = localCat.sortOrder // Force local sort order
                        mergedCategories.append(updatedCat)
                        localIds.insert(localCat.id)
                    }
                }
                
                // 3. Append any NEW items from server that weren't in local cache
                let newItems = fetchedCategories.filter { !localIds.contains($0.id) }
                mergedCategories.append(contentsOf: newItems)
                
                // 4. Update state
                self.categories = mergedCategories
                
                // 5. Retry sync to server
                reorderCategories(mergedCategories)
            } else {
                self.categories = fetchedCategories
            }
        } catch {
            print("Error fetching categories: \(error)")
        }

        do {
            self.wallets = try await client.from("wallets").select().order("sort_order", ascending: true).execute().value
        } catch {
            print("Error fetching wallets: \(error)")
        }

        do {
            self.assets = try await client.from("assets").select().order("sort_order", ascending: true).execute().value
        } catch {
            print("Error fetching assets: \(error)")
        }

        do {
            self.transactions = try await client.from("transactions").select().order("date", ascending: false).execute().value
        } catch { print("Error fetching transactions: \(error)") }

        calculateTotals()
        saveToCache()
    }

    @MainActor
    func reorderCategories(_ categories: [Category]) {
        var updatedCategories = categories
        for (index, _) in updatedCategories.enumerated() {
            updatedCategories[index].sortOrder = index
        }
        self.categories = updatedCategories
        saveToCache()
        
        // Mark as dirty
        UserDefaults.standard.set(true, forKey: pendingSortKey)
        
        // Use detached task to ensure network request survives view dismissal
        Task.detached(priority: .background) {
            do {
                // We need to access the client. Since client is let, it's thread-safe.
                try await SupabaseClient(
                    supabaseURL: URL(string: Config.supabaseUrl)!,
                    supabaseKey: Config.supabaseKey,
                    options: SupabaseClientOptions(
                        auth: .init(storage: NoOpAuthLocalStorage(), autoRefreshToken: false, emitLocalSessionAsInitialSession: true)
                    )
                ).from("categories").upsert(updatedCategories).execute()
                
                print("Successfully reordered categories")
                // Mark as clean
                await MainActor.run {
                    UserDefaults.standard.set(false, forKey: "hasPendingCategorySort")
                }
            } catch {
                print("Error reordering categories: \(error)")
            }
        }
    }

    private func calculateTotals() {
        let walletTotal = wallets.reduce(0) { $0 + $1.balance }
        let assetTotal = assets.reduce(0) { $0 + $1.value }
        self.totalBalance = walletTotal + assetTotal
        self.totalIncome = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        self.totalExpense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    @MainActor
    func addTransaction(_ transaction: Transaction) {
        // Update local state immediately
        self.transactions.insert(transaction, at: 0)
        
        // Update balances locally
        updateBalancesLocally(transaction: transaction, isAddition: true)
        calculateTotals()
        saveToCache()
        
        // Sync with server in background
        Task {
            do {
                let serverTransaction: Transaction = try await client.from("transactions").insert(transaction).select().single().execute().value
                
                // Replace the optimistic transaction with the real one from server
                if let index = self.transactions.firstIndex(where: { $0.id == nil && $0.title == transaction.title && $0.amount == transaction.amount && $0.date == transaction.date }) {
                    self.transactions[index] = serverTransaction
                }
                
                // Update balances on server
                await updateBalancesOnServer(transaction: transaction, isAddition: true)
                
                // Final fetch to ensure everything is perfectly in sync
                await fetchData()
            } catch {
                print("Error adding transaction to server: \(error)")
                // In a real app, you might want to revert the local change or show an error
                await fetchData() // Refresh to revert to server state
            }
        }
    }
    
    @MainActor
    private func updateBalancesLocally(transaction: Transaction, isAddition: Bool) {
        let multiplier = isAddition ? 1.0 : -1.0
        
        if transaction.type == .expense {
            if let walletId = transaction.walletId, let index = wallets.firstIndex(where: { $0.id == walletId }) {
                wallets[index].balance -= transaction.amount * multiplier
            }
            if let assetId = transaction.assetId, let index = assets.firstIndex(where: { $0.id == assetId }) {
                assets[index].value -= transaction.amount * multiplier
            }
        } else if transaction.type == .income {
            if let walletId = transaction.walletId, let index = wallets.firstIndex(where: { $0.id == walletId }) {
                wallets[index].balance += transaction.amount * multiplier
            }
            if let assetId = transaction.assetId, let index = assets.firstIndex(where: { $0.id == assetId }) {
                assets[index].value += transaction.amount * multiplier
            }
        } else if transaction.type == .transfer {
            if let fromId = transaction.fromWalletId, let index = wallets.firstIndex(where: { $0.id == fromId }) {
                wallets[index].balance -= transaction.amount * multiplier
            } else if let fromId = transaction.fromAssetId, let index = assets.firstIndex(where: { $0.id == fromId }) {
                assets[index].value -= transaction.amount * multiplier
            }
            
            if let toId = transaction.toWalletId, let index = wallets.firstIndex(where: { $0.id == toId }) {
                wallets[index].balance += transaction.amount * multiplier
            } else if let toId = transaction.toAssetId, let index = assets.firstIndex(where: { $0.id == toId }) {
                assets[index].value += transaction.amount * multiplier
            }
        }
    }
    
    private func updateBalancesOnServer(transaction: Transaction, isAddition: Bool) async {
        let multiplier = isAddition ? 1.0 : -1.0
        
        do {
            if transaction.type == .expense {
                if let walletId = transaction.walletId {
                    var wallet: Wallet = try await client.from("wallets").select().eq("id", value: walletId).single().execute().value
                    wallet.balance -= transaction.amount * multiplier
                    try await client.from("wallets").update(wallet).eq("id", value: walletId).execute()
                }
                if let assetId = transaction.assetId {
                    var asset: Asset = try await client.from("assets").select().eq("id", value: assetId).single().execute().value
                    asset.value -= transaction.amount * multiplier
                    try await client.from("assets").update(asset).eq("id", value: assetId).execute()
                }
            } else if transaction.type == .income {
                if let walletId = transaction.walletId {
                    var wallet: Wallet = try await client.from("wallets").select().eq("id", value: walletId).single().execute().value
                    wallet.balance += transaction.amount * multiplier
                    try await client.from("wallets").update(wallet).eq("id", value: walletId).execute()
                }
                if let assetId = transaction.assetId {
                    var asset: Asset = try await client.from("assets").select().eq("id", value: assetId).single().execute().value
                    asset.value += transaction.amount * multiplier
                    try await client.from("assets").update(asset).eq("id", value: assetId).execute()
                }
            } else if transaction.type == .transfer {
                if let fromId = transaction.fromWalletId {
                    var wallet: Wallet = try await client.from("wallets").select().eq("id", value: fromId).single().execute().value
                    wallet.balance -= transaction.amount * multiplier
                    try await client.from("wallets").update(wallet).eq("id", value: fromId).execute()
                } else if let fromId = transaction.fromAssetId {
                    var asset: Asset = try await client.from("assets").select().eq("id", value: fromId).single().execute().value
                    asset.value -= transaction.amount * multiplier
                    try await client.from("assets").update(asset).eq("id", value: fromId).execute()
                }
                
                if let toId = transaction.toWalletId {
                    var wallet: Wallet = try await client.from("wallets").select().eq("id", value: toId).single().execute().value
                    wallet.balance += transaction.amount * multiplier
                    try await client.from("wallets").update(wallet).eq("id", value: toId).execute()
                } else if let toId = transaction.toAssetId {
                    var asset: Asset = try await client.from("assets").select().eq("id", value: toId).single().execute().value
                    asset.value += transaction.amount * multiplier
                    try await client.from("assets").update(asset).eq("id", value: toId).execute()
                }
            }
        } catch {
            print("Error updating balances on server: \(error)")
        }
    }
    
    @MainActor
    func deleteTransaction(_ transaction: Transaction) {
        // Optimistic local update
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions.remove(at: index)
        }
        
        // Update balances locally
        updateBalancesLocally(transaction: transaction, isAddition: false)
        calculateTotals()
        saveToCache()
        
        // Sync with server in background
        Task {
            do {
                // Revert balances on server
                await updateBalancesOnServer(transaction: transaction, isAddition: false)
                
                // Delete transaction on server
                try await client.from("transactions").delete().eq("id", value: transaction.id!).execute()
                
                // Final fetch to ensure consistency
                await fetchData()
            } catch {
                print("Error deleting transaction on server: \(error)")
                await fetchData()
            }
        }
    }
    
    @MainActor
    func updateTransaction(_ transaction: Transaction) {
        // Find old transaction to revert its balance changes
        guard let oldTransactionIndex = transactions.firstIndex(where: { $0.id == transaction.id }) else { return }
        let oldTransaction = transactions[oldTransactionIndex]
        
        // Optimistic local update
        transactions[oldTransactionIndex] = transaction
        
        // Revert old balances, then apply new balances
        updateBalancesLocally(transaction: oldTransaction, isAddition: false)
        updateBalancesLocally(transaction: transaction, isAddition: true)
        
        calculateTotals()
        saveToCache()
        
        // Sync with server in background
        Task {
            do {
                // Revert old balances on server
                await updateBalancesOnServer(transaction: oldTransaction, isAddition: false)
                
                // Apple new balances on server
                await updateBalancesOnServer(transaction: transaction, isAddition: true)
                
                // Update transaction on server
                try await client.from("transactions").update(transaction).eq("id", value: transaction.id!).execute()
                
                // Final fetch to ensure consistency
                await fetchData()
            } catch {
                print("Error updating transaction on server: \(error)")
                await fetchData()
            }
        }
    }
    
    @MainActor
    func addWallet(_ wallet: Wallet) async {
        do {
            let _: Wallet = try await client.from("wallets").insert(wallet).select().single().execute().value
            await fetchData()
        } catch {
            print("Error adding wallet: \(error)")
        }
    }
    
    @MainActor
    func deleteWallet(id: Int) async {
        if let index = wallets.firstIndex(where: { $0.id == id }) {
            wallets.remove(at: index)
        }
        
        do {
            try await client.from("transactions").delete().eq("wallet_id", value: id).execute()
            
            try await client.from("wallets").delete().eq("id", value: id).execute()
            await fetchData()
        } catch {
            print("Error deleting wallet: \(error)")
            await fetchData()
        }
    }
    
    @MainActor
    func addAsset(_ asset: Asset) async {
        do {
            let _: Asset = try await client.from("assets").insert(asset).select().single().execute().value
            await fetchData()
        } catch {
            print("Error adding asset: \(error)")
        }
    }
    
    @MainActor
    func deleteAsset(id: Int) async {
        if let index = assets.firstIndex(where: { $0.id == id }) {
            assets.remove(at: index)
        }
        
        do {
            try await client.from("transactions").delete().eq("asset_id", value: id).execute()
            
            try await client.from("assets").delete().eq("id", value: id).execute()
            await fetchData()
        } catch {
            print("Error deleting asset: \(error)")
            await fetchData()
        }
    }
    
    @MainActor
    func updateWallet(_ wallet: Wallet) async {
        do {
            try await client.from("wallets").update(wallet).eq("id", value: wallet.id!).execute()
            await fetchData()
        } catch {
            print("Error updating wallet: \(error)")
        }
    }
    
    @MainActor
    func updateAsset(_ asset: Asset) async {
        do {
            try await client.from("assets").update(asset).eq("id", value: asset.id!).execute()
            await fetchData()
        } catch {
            print("Error updating asset: \(error)")
        }
    }
    
    @MainActor
    func reorderWallets(_ wallets: [Wallet]) async {
        self.wallets = wallets
        saveToCache()
        
        do {
            for (index, wallet) in wallets.enumerated() {
                var updatedWallet = wallet
                updatedWallet.sortOrder = index
                try await client.from("wallets").update(updatedWallet).eq("id", value: wallet.id!).execute()
            }
        } catch {
            print("Error reordering wallets: \(error)")
            await fetchData()
        }
    }
    
    @MainActor
    func reorderAssets(_ assets: [Asset]) async {
        self.assets = assets
        saveToCache()
        
        do {
            for (index, asset) in assets.enumerated() {
                var updatedAsset = asset
                updatedAsset.sortOrder = index
                try await client.from("assets").update(updatedAsset).eq("id", value: asset.id!).execute()
            }
        } catch {
            print("Error reordering assets: \(error)")
            await fetchData()
        }
    }
    
    func getCategoryIcon(for name: String) -> String {
        return categories.first(where: { $0.name == name })?.icon ?? "questionmark.circle"
    }
    
    @MainActor
    func addCategory(_ category: Category) async {
        do {
            print("Attempting to add category: \(category.name), type: \(category.type)")
            let result: Category = try await client.from("categories").insert(category).select().single().execute().value
            print("Successfully added category to DB: \(result.name)")
            
            var currentCategories = self.categories
            currentCategories.append(result)
            self.categories = currentCategories.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
            
            saveToCache()
            
            await fetchData()
        } catch {
            print("Error adding category: \(error)")
        }
    }
    
    @MainActor
    func deleteCategory(id: String) async {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories.remove(at: index)
        }
        
        do {
            try await client.from("categories").delete().eq("id", value: id).execute()
            print("Successfully deleted category with id: \(id)")
            
            saveToCache()
            
            await fetchData()
        } catch {
            print("Error deleting category: \(error)")
            await fetchData()
        }
    }
    
    @MainActor
    func updateCategory(_ category: Category) async {
        do {
            try await client.from("categories").update(category).eq("id", value: category.id).execute()
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                categories[index] = category
            }
            saveToCache()
            await fetchData()
        } catch {
            print("Error updating category: \(error)")
        }
    }
    
    func getWalletName(id: Int?) -> String {
        guard let id = id else { return "Unknown Wallet" }
        return wallets.first(where: { $0.id == id })?.name ?? "Unknown Wallet"
    }
    
    func getAssetName(id: Int?) -> String {
        guard let id = id else { return "Unknown Asset" }
        return assets.first(where: { $0.id == id })?.name ?? "Unknown Asset"
    }
}

struct NoOpAuthLocalStorage: AuthLocalStorage {
    func store(key: String, value: Data) throws {}
    func retrieve(key: String) throws -> Data? { return nil }
    func remove(key: String) throws {}
}

struct CacheData: Codable {
    let transactions: [Transaction]
    let wallets: [Wallet]
    let assets: [Asset]
    let categories: [Category]
}
