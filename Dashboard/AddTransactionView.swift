import SwiftUI

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager = DataManager.shared
    
    var transactionToEdit: Transaction?
    
    @State private var amount: String = ""
    @State private var selectedCategory: Category?
    @State private var date = Date()
    
    // For Income/Expense
    @State private var selectedWallet: Wallet?
    @State private var selectedAsset: Asset?
    @State private var accountType: String = "Wallet"
    
    // For Transfer
    @State private var fromAccountType: String = "Wallet"
    @State private var toAccountType: String = "Wallet"
    @State private var selectedFromWallet: Wallet?
    @State private var selectedToWallet: Wallet?
    @State private var selectedFromAsset: Asset?
    @State private var selectedToAsset: Asset?
    
    @State private var title: String = ""
    @State private var type: Transaction.TransactionType = .expense
    
    init(transactionToEdit: Transaction? = nil) {
        self.transactionToEdit = transactionToEdit
        
        if let transaction = transactionToEdit {
            _amount = State(initialValue: String(Int(transaction.amount)))
            _date = State(initialValue: transaction.date)
            _title = State(initialValue: transaction.title)
            _type = State(initialValue: transaction.type)
            
            if let category = DataManager.shared.categories.first(where: { $0.name == transaction.category }) {
                _selectedCategory = State(initialValue: category)
            }
            
            if transaction.type == .transfer {
                if let fromWalletId = transaction.fromWalletId, let wallet = DataManager.shared.wallets.first(where: { $0.id == fromWalletId }) {
                    _selectedFromWallet = State(initialValue: wallet)
                    _fromAccountType = State(initialValue: "Wallet")
                } else if let fromAssetId = transaction.fromAssetId, let asset = DataManager.shared.assets.first(where: { $0.id == fromAssetId }) {
                    _selectedFromAsset = State(initialValue: asset)
                    _fromAccountType = State(initialValue: "Asset")
                }
                
                if let toWalletId = transaction.toWalletId, let wallet = DataManager.shared.wallets.first(where: { $0.id == toWalletId }) {
                    _selectedToWallet = State(initialValue: wallet)
                    _toAccountType = State(initialValue: "Wallet")
                } else if let toAssetId = transaction.toAssetId, let asset = DataManager.shared.assets.first(where: { $0.id == toAssetId }) {
                    _selectedToAsset = State(initialValue: asset)
                    _toAccountType = State(initialValue: "Asset")
                }
            } else {
                if let walletId = transaction.walletId, let wallet = DataManager.shared.wallets.first(where: { $0.id == walletId }) {
                    _selectedWallet = State(initialValue: wallet)
                    _accountType = State(initialValue: "Wallet")
                } else if let assetId = transaction.assetId, let asset = DataManager.shared.assets.first(where: { $0.id == assetId }) {
                    _selectedAsset = State(initialValue: asset)
                    _accountType = State(initialValue: "Asset")
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                Form {
                    detailsSection
                    
                    if type != .transfer {
                        categorySection
                        accountSection
                    } else {
                        transferSection
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(transactionToEdit == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveTransaction()
                }
                .disabled(isSaveDisabled)
            )
        }
    }
    
    var isSaveDisabled: Bool {
        if amount.isEmpty { return true }
        if type == .transfer {
            let fromValid = (fromAccountType == "Wallet" && selectedFromWallet != nil) || (fromAccountType == "Asset" && selectedFromAsset != nil)
            let toValid = (toAccountType == "Wallet" && selectedToWallet != nil) || (toAccountType == "Asset" && selectedToAsset != nil)
            return !fromValid || !toValid
        } else {
            let accountValid = (accountType == "Wallet" && selectedWallet != nil) || (accountType == "Asset" && selectedAsset != nil)
            return selectedCategory == nil || !accountValid
        }
    }
    
    var detailsSection: some View {
        Section(header: Text("Details")) {
            Picker("Type", selection: $type) {
                Text("Expense").tag(Transaction.TransactionType.expense)
                Text("Income").tag(Transaction.TransactionType.income)
                Text("Transfer").tag(Transaction.TransactionType.transfer)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            TextField("Title", text: $title)
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
            
            DatePicker("Date", selection: $date, displayedComponents: .date)
        }
    }
    
    var categorySection: some View {
        Section(header: Text("Category")) {
            Picker("Category", selection: $selectedCategory) {
                Text("Select Category").tag(nil as Category?)
                ForEach(dataManager.categories.filter { $0.type.rawValue == type.rawValue }) { category in
                    Label(category.name, systemImage: category.icon).tag(category as Category?)
                }
            }
        }
    }
    
    var accountSection: some View {
        Section(header: Text("Account")) {
            Picker("Type", selection: $accountType) {
                Text("Wallet").tag("Wallet")
                Text("Asset").tag("Asset")
            }
            .pickerStyle(SegmentedPickerStyle())
            if accountType == "Wallet" {
                Picker("Wallet", selection: $selectedWallet) {
                    Text("Select Wallet").tag(nil as Wallet?)
                    ForEach(dataManager.wallets) { wallet in
                        Text(wallet.name).tag(wallet as Wallet?)
                    }
                }
            } else {
                Picker("Asset", selection: $selectedAsset) {
                    Text("Select Asset").tag(nil as Asset?)
                    ForEach(dataManager.assets) { asset in
                        Text(asset.name).tag(asset as Asset?)
                    }
                }
            }
        }
    }
    
    var transferSection: some View {
        Group {
            Section(header: Text("From")) {
                Picker("Type", selection: $fromAccountType) {
                    Text("Wallet").tag("Wallet")
                    Text("Asset").tag("Asset")
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if fromAccountType == "Wallet" {
                    Picker("Wallet", selection: $selectedFromWallet) {
                        Text("Select Wallet").tag(nil as Wallet?)
                        ForEach(dataManager.wallets) { wallet in
                            Text(wallet.name).tag(wallet as Wallet?)
                        }
                    }
                } else {
                    Picker("Asset", selection: $selectedFromAsset) {
                        Text("Select Asset").tag(nil as Asset?)
                        ForEach(dataManager.assets) { asset in
                            Text(asset.name).tag(asset as Asset?)
                        }
                    }
                }
            }
            
            Section(header: Text("To")) {
                Picker("Type", selection: $toAccountType) {
                    Text("Wallet").tag("Wallet")
                    Text("Asset").tag("Asset")
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if toAccountType == "Wallet" {
                    Picker("Wallet", selection: $selectedToWallet) {
                        Text("Select Wallet").tag(nil as Wallet?)
                        ForEach(dataManager.wallets) { wallet in
                            Text(wallet.name).tag(wallet as Wallet?)
                        }
                    }
                } else {
                    Picker("Asset", selection: $selectedToAsset) {
                        Text("Select Asset").tag(nil as Asset?)
                        ForEach(dataManager.assets) { asset in
                            Text(asset.name).tag(asset as Asset?)
                        }
                    }
                }
            }
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let transaction: Transaction
        
        if type == .transfer {
            transaction = Transaction(
                id: transactionToEdit?.id,
                walletId: nil,
                assetId: nil,
                fromWalletId: fromAccountType == "Wallet" ? selectedFromWallet?.id : nil,
                toWalletId: toAccountType == "Wallet" ? selectedToWallet?.id : nil,
                fromAssetId: fromAccountType == "Asset" ? selectedFromAsset?.id : nil,
                toAssetId: toAccountType == "Asset" ? selectedToAsset?.id : nil,
                title: title.isEmpty ? "Transfer" : title,
                category: "Transfer",
                date: date,
                amount: amountValue,
                type: type
            )
        } else {
            guard let category = selectedCategory else { return }
            
            transaction = Transaction(
                id: transactionToEdit?.id,
                walletId: accountType == "Wallet" ? selectedWallet?.id : nil,
                assetId: accountType == "Asset" ? selectedAsset?.id : nil,
                fromWalletId: nil,
                toWalletId: nil,
                fromAssetId: nil,
                toAssetId: nil,
                title: title.isEmpty ? category.name : title,
                category: category.name,
                date: date,
                amount: amountValue,
                type: type
            )
        }
        
        Task {
            if transactionToEdit != nil {
                await dataManager.updateTransaction(transaction)
            } else {
                await dataManager.addTransaction(transaction)
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
}
