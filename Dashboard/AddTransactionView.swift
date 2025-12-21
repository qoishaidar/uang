import SwiftUI

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager = DataManager.shared
    
    var transactionToEdit: Transaction?
    
    @State private var amount: String = ""
    @State private var selectedCategory: Category?
    @State private var date = Date()
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, amount
    }
    
    @State private var selectedWallet: Wallet?
    @State private var selectedAsset: Asset?
    @State private var accountType: String = "Wallet"
    
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
            .onTapGesture {
                focusedField = nil
            }
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
                .focused($focusedField, equals: .title)
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .amount)
            
            DatePicker("Date", selection: $date, displayedComponents: .date)
        }
    }
    
    var categorySection: some View {
        Section(header: Text("Category")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dataManager.categories.filter { $0.type.rawValue == type.rawValue }) { category in
                        CategorySelectItemView(
                            name: category.name,
                            icon: category.icon,
                            isSelected: selectedCategory?.id == category.id
                        )
                        .onTapGesture {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
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
            .padding(.vertical, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if accountType == "Wallet" {
                        ForEach(dataManager.wallets) { wallet in
                            AccountSelectItemView(
                                name: wallet.name,
                                balance: wallet.balance,
                                isSelected: selectedWallet?.id == wallet.id,
                                isHidden: dataManager.isAmountHidden
                            )
                            .onTapGesture {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                selectedWallet = wallet
                            }
                        }
                    } else {
                        ForEach(dataManager.assets) { asset in
                            AccountSelectItemView(
                                name: asset.name,
                                balance: asset.value,
                                isSelected: selectedAsset?.id == asset.id,
                                isHidden: dataManager.isAmountHidden
                            )
                            .onTapGesture {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                selectedAsset = asset
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
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
                .padding(.vertical, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if fromAccountType == "Wallet" {
                            ForEach(dataManager.wallets) { wallet in
                                AccountSelectItemView(
                                    name: wallet.name,
                                    balance: wallet.balance,
                                    isSelected: selectedFromWallet?.id == wallet.id,
                                    isHidden: dataManager.isAmountHidden
                                )
                                .onTapGesture {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    selectedFromWallet = wallet
                                }
                            }
                        } else {
                            ForEach(dataManager.assets) { asset in
                                AccountSelectItemView(
                                    name: asset.name,
                                    balance: asset.value,
                                    isSelected: selectedFromAsset?.id == asset.id,
                                    isHidden: dataManager.isAmountHidden
                                )
                                .onTapGesture {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    selectedFromAsset = asset
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("To")) {
                Picker("Type", selection: $toAccountType) {
                    Text("Wallet").tag("Wallet")
                    Text("Asset").tag("Asset")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if toAccountType == "Wallet" {
                            ForEach(dataManager.wallets) { wallet in
                                AccountSelectItemView(
                                    name: wallet.name,
                                    balance: wallet.balance,
                                    isSelected: selectedToWallet?.id == wallet.id,
                                    isHidden: dataManager.isAmountHidden
                                )
                                .onTapGesture {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    selectedToWallet = wallet
                                }
                            }
                        } else {
                            ForEach(dataManager.assets) { asset in
                                AccountSelectItemView(
                                    name: asset.name,
                                    balance: asset.value,
                                    isSelected: selectedToAsset?.id == asset.id,
                                    isHidden: dataManager.isAmountHidden
                                )
                                .onTapGesture {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    selectedToAsset = asset
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
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

struct AccountSelectItemView: View {
    let name: String
    let balance: Double
    let isSelected: Bool
    let isHidden: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : Theme.textSecondary)
            
            Text(balance.formatted(.currency(code: "IDR")))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : Theme.textPrimary)
                .hideAmount(if: isHidden)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minWidth: 120, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Theme.primary : Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Theme.primary : Color.primary.opacity(0.1), lineWidth: 1)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct CategorySelectItemView: View {
    let name: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .white : Theme.primary)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(isSelected ? .white.opacity(0.2) : Theme.primary.opacity(0.1))
                )
            
            Text(name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : Theme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(minWidth: 80)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Theme.primary : Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Theme.primary : Color.primary.opacity(0.1), lineWidth: 1)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
