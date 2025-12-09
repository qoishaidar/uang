import SwiftUI

struct WalletDetailView: View {
    let wallet: Wallet
    @ObservedObject var dataManager = DataManager.shared
    @State private var transactionToEdit: Transaction?
    @State private var selectedFilter: TimeFilter = .all
    
    enum TimeFilter: String, CaseIterable {
        case day = "Day"
        case month = "Month"
        case year = "Year"
        case all = "All"
    }
    
    var filteredTransactions: [Transaction] {
        let walletTransactions = dataManager.transactions.filter {
            $0.walletId == wallet.id || $0.fromWalletId == wallet.id || $0.toWalletId == wallet.id
        }
        
        // Simple filter logic (can be expanded)
        switch selectedFilter {
        case .day:
            return walletTransactions.filter { Calendar.current.isDateInToday($0.date) }
        case .month:
            return walletTransactions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        case .year:
            return walletTransactions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .year) }
        case .all:
            return walletTransactions
        }
    }
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Card Detail
                    BankCardView(
                        name: wallet.name,
                        balance: wallet.balance,
                        color: "#1E1E1E",
                        last4: wallet.last4,
                        type: wallet.type,
                        isHidden: dataManager.isAmountHidden
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TimeFilter.allCases, id: \.self) { filter in
                                Button(action: { selectedFilter = filter }) {
                                    Text(filter.rawValue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? Color.white : Color.white.opacity(0.1))
                                        .foregroundColor(selectedFilter == filter ? .black : .white)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Transactions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("History")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal)
                        
                        ForEach(filteredTransactions) { transaction in
                            TransactionRow(transaction: transaction, isHidden: dataManager.isAmountHidden)
                                .contextMenu {
                                    Button {
                                        transactionToEdit = transaction
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        Task {
                                            await dataManager.deleteTransaction(id: transaction.id!)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task {
                                            await dataManager.deleteTransaction(id: transaction.id!)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        transactionToEdit = transaction
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(wallet.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $transactionToEdit) { transaction in
            AddTransactionView(transactionToEdit: transaction)
        }
    }
}
