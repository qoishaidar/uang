import SwiftUI

struct AssetDetailView: View {
    let asset: Asset
    @ObservedObject var dataManager = DataManager.shared
    @State private var transactionToEdit: Transaction?
    @State private var selectedFilter: TimeFilter = .all
    @State private var showingDeleteAlert = false
    @State private var transactionToDelete: Transaction?
    
    enum TimeFilter: String, CaseIterable {
        case day = "Day"
        case month = "Month"
        case year = "Year"
        case all = "All"
    }
    
    var filteredTransactions: [Transaction] {
        let assetTransactions = dataManager.transactions.filter {
            $0.assetId == asset.id || $0.fromAssetId == asset.id || $0.toAssetId == asset.id
        }
        
        switch selectedFilter {
        case .day:
            return assetTransactions.filter { Calendar.current.isDateInToday($0.date) }
        case .month:
            return assetTransactions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        case .year:
            return assetTransactions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .year) }
        case .all:
            return assetTransactions
        }
    }
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    BankCardView(
                        name: asset.name,
                        balance: asset.value,
                        color: "#1E1E1E",
                        last4: asset.symbol,
                        type: asset.type,
                        isHidden: dataManager.isAmountHidden
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TimeFilter.allCases, id: \.self) { filter in
                                Button(action: { selectedFilter = filter }) {
                                    Text(filter.rawValue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? Theme.primary : Theme.textPrimary.opacity(0.1))
                                        .foregroundColor(selectedFilter == filter ? .white : Theme.textPrimary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                        historySection
                    .padding(.horizontal)
                }
            }
        }
        .alert("Delete Transaction", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let transaction = transactionToDelete {
                    dataManager.deleteTransaction(transaction)
                }
            }
        } message: {
            Text("Are you sure you want to delete this transaction?")
        }
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $transactionToEdit) { transaction in
            AddTransactionView(transactionToEdit: transaction)
        }
    }
    
    private var historySection: some View {
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
                            transactionToDelete = transaction
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }
}
