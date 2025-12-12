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
            auth: .init(storage: NoOpAuthLocalStorage(), autoRefreshToken: false)
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
    
    @MainActor
    func fetchData() async {
        do {
            async let categoriesTask: [Category] = client.from("categories").select().order("sort_order", ascending: true).execute().value
            async let walletsTask: [Wallet] = client.from("wallets").select().order("sort_order", ascending: true).execute().value
            async let assetsTask: [Asset] = client.from("assets").select().order("sort_order", ascending: true).execute().value
            async let transactionsTask: [Transaction] = client.from("transactions").select().order("date", ascending: false).execute().value
            
            let (fetchedCategories, fetchedWallets, fetchedAssets, fetchedTransactions) = try await (categoriesTask, walletsTask, assetsTask, transactionsTask)
            
            self.categories = fetchedCategories
            self.wallets = fetchedWallets
            self.assets = fetchedAssets
            self.transactions = fetchedTransactions
            
            calculateTotals()
            saveToCache()
            
        } catch {
            print("Error fetching data: \(error)")
        }
    }

    // ... (existing code)

    @MainActor
    func reorderCategories(_ categories: [Category]) async {
        // Update local state with new sort orders
        var updatedCategories = categories
        for (index, _) in updatedCategories.enumerated() {
            updatedCategories[index].sortOrder = index
        }
        self.categories = updatedCategories
        
        // Save to local cache immediately
        saveToCache()
        
        do {
            // Update each category in Supabase
            for category in updatedCategories {
                try await client.from("categories").update(category).eq("id", value: category.id).execute()
            }
            print("Successfully reordered categories")
        } catch {
            print("Error reordering categories: \(error)")
            await fetchData()
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
    func addTransaction(_ transaction: Transaction) async {
        do {
            let _: Transaction = try await client.from("transactions").insert(transaction).select().single().execute().value
            
            if transaction.type == .expense {
                if let walletId = transaction.walletId, let index = wallets.firstIndex(where: { $0.id == walletId }) {
                    var wallet = wallets[index]
                    wallet.balance -= transaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: walletId).execute()
                }
                
                if let assetId = transaction.assetId, let index = assets.firstIndex(where: { $0.id == assetId }) {
                    var asset = assets[index]
                    asset.value -= transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: assetId).execute()
                }
            } else if transaction.type == .income {
                if let walletId = transaction.walletId, let index = wallets.firstIndex(where: { $0.id == walletId }) {
                    var wallet = wallets[index]
                    wallet.balance += transaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: walletId).execute()
                }
                
                if let assetId = transaction.assetId, let index = assets.firstIndex(where: { $0.id == assetId }) {
                    var asset = assets[index]
                    asset.value += transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: assetId).execute()
                }
            } else if transaction.type == .transfer {
                if let fromWalletId = transaction.fromWalletId, let index = wallets.firstIndex(where: { $0.id == fromWalletId }) {
                    var wallet = wallets[index]
                    wallet.balance -= transaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: fromWalletId).execute()
                } else if let fromAssetId = transaction.fromAssetId, let index = assets.firstIndex(where: { $0.id == fromAssetId }) {
                    var asset = assets[index]
                    asset.value -= transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: fromAssetId).execute()
                }
                
                if let toWalletId = transaction.toWalletId {
                     var wallet: Wallet = try await client.from("wallets").select().eq("id", value: toWalletId).single().execute().value
                     wallet.balance += transaction.amount
                     try await client.from("wallets").update(wallet).eq("id", value: toWalletId).execute()
                } else if let toAssetId = transaction.toAssetId {
                    var asset: Asset = try await client.from("assets").select().eq("id", value: toAssetId).single().execute().value
                    asset.value += transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: toAssetId).execute()
                }
            }
            
            await fetchData()
        } catch {
            print("Error adding transaction: \(error)")
        }
    }
    
    @MainActor
    func deleteTransaction(id: Int) async {
        do {
            let transaction: Transaction = try await client.from("transactions").select().eq("id", value: id).single().execute().value
            
            if transaction.type == .expense {
                if let walletId = transaction.walletId, let index = wallets.firstIndex(where: { $0.id == walletId }) {
                    var wallet = wallets[index]
                    wallet.balance += transaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: walletId).execute()
                }
                
                if let assetId = transaction.assetId, let index = assets.firstIndex(where: { $0.id == assetId }) {
                    var asset = assets[index]
                    asset.value += transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: assetId).execute()
                }
            } else if transaction.type == .income {
                if let walletId = transaction.walletId, let index = wallets.firstIndex(where: { $0.id == walletId }) {
                    var wallet = wallets[index]
                    wallet.balance -= transaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: walletId).execute()
                }
                
                if let assetId = transaction.assetId, let index = assets.firstIndex(where: { $0.id == assetId }) {
                    var asset = assets[index]
                    asset.value -= transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: assetId).execute()
                }
            } else if transaction.type == .transfer {
                if let fromWalletId = transaction.fromWalletId, let index = wallets.firstIndex(where: { $0.id == fromWalletId }) {
                    var wallet = wallets[index]
                    wallet.balance += transaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: fromWalletId).execute()
                } else if let fromAssetId = transaction.fromAssetId, let index = assets.firstIndex(where: { $0.id == fromAssetId }) {
                    var asset = assets[index]
                    asset.value += transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: fromAssetId).execute()
                }
                
                if let toWalletId = transaction.toWalletId, let index = wallets.firstIndex(where: { $0.id == toWalletId }) {
                    var wallet = wallets[index]
                    wallet.balance -= transaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: toWalletId).execute()
                } else if let toAssetId = transaction.toAssetId, let index = assets.firstIndex(where: { $0.id == toAssetId }) {
                    var asset = assets[index]
                    asset.value -= transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: toAssetId).execute()
                }
            }
            
            try await client.from("transactions").delete().eq("id", value: id).execute()
            await fetchData()
        } catch {
            print("Error deleting transaction: \(error)")
        }
    }
    
    @MainActor
    func updateTransaction(_ transaction: Transaction) async {
        do {
            let oldTransaction: Transaction = try await client.from("transactions").select().eq("id", value: transaction.id!).single().execute().value
            
            if oldTransaction.type == .expense {
                if let walletId = oldTransaction.walletId, let index = wallets.firstIndex(where: { $0.id == walletId }) {
                    var wallet = wallets[index]
                    wallet.balance += oldTransaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: walletId).execute()
                }
                if let assetId = oldTransaction.assetId, let index = assets.firstIndex(where: { $0.id == assetId }) {
                    var asset = assets[index]
                    asset.value += oldTransaction.amount
                    try await client.from("assets").update(asset).eq("id", value: assetId).execute()
                }
            } else if oldTransaction.type == .income {
                if let walletId = oldTransaction.walletId, let index = wallets.firstIndex(where: { $0.id == walletId }) {
                    var wallet = wallets[index]
                    wallet.balance -= oldTransaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: walletId).execute()
                }
                if let assetId = oldTransaction.assetId, let index = assets.firstIndex(where: { $0.id == assetId }) {
                    var asset = assets[index]
                    asset.value -= oldTransaction.amount
                    try await client.from("assets").update(asset).eq("id", value: assetId).execute()
                }
            } else if oldTransaction.type == .transfer {
                if let fromWalletId = oldTransaction.fromWalletId {
                    var wallet: Wallet = try await client.from("wallets").select().eq("id", value: fromWalletId).single().execute().value
                    wallet.balance += oldTransaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: fromWalletId).execute()
                } else if let fromAssetId = oldTransaction.fromAssetId {
                    var asset: Asset = try await client.from("assets").select().eq("id", value: fromAssetId).single().execute().value
                    asset.value += oldTransaction.amount
                    try await client.from("assets").update(asset).eq("id", value: fromAssetId).execute()
                }
                
                if let toWalletId = oldTransaction.toWalletId {
                    var wallet: Wallet = try await client.from("wallets").select().eq("id", value: toWalletId).single().execute().value
                    wallet.balance -= oldTransaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: toWalletId).execute()
                } else if let toAssetId = oldTransaction.toAssetId {
                    var asset: Asset = try await client.from("assets").select().eq("id", value: toAssetId).single().execute().value
                    asset.value -= oldTransaction.amount
                    try await client.from("assets").update(asset).eq("id", value: toAssetId).execute()
                }
            }
            
            if transaction.type == .expense {
                if let walletId = transaction.walletId {
                    var wallet: Wallet = try await client.from("wallets").select().eq("id", value: walletId).single().execute().value
                    wallet.balance -= transaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: walletId).execute()
                }
                if let assetId = transaction.assetId {
                    var asset: Asset = try await client.from("assets").select().eq("id", value: assetId).single().execute().value
                    asset.value -= transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: assetId).execute()
                }
            } else if transaction.type == .income {
                if let walletId = transaction.walletId {
                    var wallet: Wallet = try await client.from("wallets").select().eq("id", value: walletId).single().execute().value
                    wallet.balance += transaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: walletId).execute()
                }
                if let assetId = transaction.assetId {
                    var asset: Asset = try await client.from("assets").select().eq("id", value: assetId).single().execute().value
                    asset.value += transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: assetId).execute()
                }
            } else if transaction.type == .transfer {
                if let fromWalletId = transaction.fromWalletId {
                    var wallet: Wallet = try await client.from("wallets").select().eq("id", value: fromWalletId).single().execute().value
                    wallet.balance -= transaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: fromWalletId).execute()
                } else if let fromAssetId = transaction.fromAssetId {
                    var asset: Asset = try await client.from("assets").select().eq("id", value: fromAssetId).single().execute().value
                    asset.value -= transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: fromAssetId).execute()
                }
                
                if let toWalletId = transaction.toWalletId {
                    var wallet: Wallet = try await client.from("wallets").select().eq("id", value: toWalletId).single().execute().value
                    wallet.balance += transaction.amount
                    try await client.from("wallets").update(wallet).eq("id", value: toWalletId).execute()
                } else if let toAssetId = transaction.toAssetId {
                    var asset: Asset = try await client.from("assets").select().eq("id", value: toAssetId).single().execute().value
                    asset.value += transaction.amount
                    try await client.from("assets").update(asset).eq("id", value: toAssetId).execute()
                }
            }
            
            try await client.from("transactions").update(transaction).eq("id", value: transaction.id!).execute()
            
            await fetchData()
        } catch {
            print("Error updating transaction: \(error)")
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
            
            // Manually update local state immediately to ensure UI responsiveness
            var currentCategories = self.categories
            currentCategories.append(result)
            // Sort by sortOrder (if available) or just append
            self.categories = currentCategories.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
            
            // Also fetch fresh data
            await fetchData()
        } catch {
            print("Error adding category: \(error)")
            // Fallback: if DB insert fails, we don't update local state
        }
    }
    
    @MainActor
    func deleteCategory(id: String) async {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories.remove(at: index)
        }
        
        do {
            // Optional: Handle transactions associated with this category if needed
            // For now, we just delete the category. Transactions might just show the old category string or need migration.
            // Since Transaction stores category as String (name), deleting the category definition might not break existing transactions immediately
            // but it's good practice to consider referential integrity.
            // However, the current Transaction model uses 'category: String', which is the name, not ID.
            // If we delete the category, the name remains in transactions.
            
            try await client.from("categories").delete().eq("id", value: id).execute()
            print("Successfully deleted category with id: \(id)")
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
            print("Successfully updated category: \(category.name)")
            
            // Manually update local state immediately
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                categories[index] = category
            }
            
            await fetchData()
        } catch {
            print("Error updating category: \(error)")
        }
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
