import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingAddTransaction = false
    
    var totalBalance: Double {
        let walletTotal = dataManager.wallets.reduce(0) { $0 + $1.balance }
        let assetTotal = dataManager.assets.reduce(0) { $0 + $1.value }
        return walletTotal + assetTotal
    }
    
    var income: Double {
        dataManager.transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var expense: Double {
        dataManager.transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Dashboard")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.textPrimary)
                                Text("Sugeng Rawuh Mas Qois")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    dataManager.isAmountHidden.toggle()
                                }
                            }) {
                                Image(systemName: dataManager.isAmountHidden ? "eye.slash.fill" : "eye.fill")
                                    .font(.title2)
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding(.trailing, 8)
                            
                            Button(action: { showingAddTransaction = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        .padding(.horizontal)
                        
                        TotalBalanceCard(balance: totalBalance, income: income, expense: expense, isHidden: dataManager.isAmountHidden)
                            .padding(.horizontal)
                        
                        ExpenseChartView(transactions: dataManager.transactions, isHidden: dataManager.isAmountHidden)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Activity")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                NavigationLink(destination: AllTransactionsView()) {
                                    Text("View All")
                                        .foregroundColor(Theme.textSecondary)
                                        .font(.subheadline)
                                }
                            }
                            
                            ForEach(dataManager.transactions.prefix(5)) { transaction in
                                TransactionRow(transaction: transaction, isHidden: dataManager.isAmountHidden)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            Task {
                                                await DataManager.shared.deleteTransaction(id: transaction.id!)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 140)
                    }
                    .padding(.top)
                }
                .refreshable {
                    await dataManager.fetchData()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
    }
}

struct TotalBalanceCard: View {
    let balance: Double
    let income: Double
    let expense: Double
    var isHidden: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Balance")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                Text(balance.formatted(.currency(code: "IDR")))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .hideAmount(if: isHidden)
            }
            
            Divider().background(Color.primary.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.down.left")
                        .foregroundColor(.green)
                        Text("Income")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Text(income.formatted(.currency(code: "IDR")))
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                        .hideAmount(if: isHidden)
                }
                Spacer()
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.up.right")
                        .foregroundColor(.red)
                        Text("Expense")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Text(expense.formatted(.currency(code: "IDR")))
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                        .hideAmount(if: isHidden)
                }
            }
        }
        .padding(24)
        .glassCard()
    }
}



struct ExpenseChartView: View {
    let transactions: [Transaction]
    var isHidden: Bool
    @State private var showDetails = false
    
    var aggregatedExpenses: [(category: String, amount: Double)] {
        let expenses = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { category, transactions in
            (category: category, amount: abs(transactions.reduce(0) { $0 + $1.amount }))
        }.sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Expenses")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            
            Chart {
                ForEach(aggregatedExpenses, id: \.category) { item in
                    BarMark(
                        x: .value("Category", item.category),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(Color.primary.opacity(0.8))
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                        .foregroundStyle(Color.primary.opacity(0.2))
                    if isHidden {
                        AxisValueLabel { Text("•••") }
                    } else {
                        AxisValueLabel(format: .currency(code: "IDR"))
                            .foregroundStyle(Color.primary.opacity(0.5))
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartXScale(domain: aggregatedExpenses.map { $0.category })
            
            if !aggregatedExpenses.isEmpty {
                Divider()
                    .background(Color.primary.opacity(0.2))
                
                Button(action: { withAnimation { showDetails.toggle() } }) {
                    HStack {
                        Text(showDetails ? "Hide Details" : "Show Details")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showDetails ? 180 : 0))
                    }
                    .foregroundColor(Theme.textPrimary)
                }
                
                if showDetails {
                    VStack(spacing: 12) {
                        ForEach(aggregatedExpenses, id: \.category) { item in
                            HStack {
                                Circle()
                                    .fill(Color.primary.opacity(0.8))
                                    .frame(width: 8, height: 8)
                                Text(item.category)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text(item.amount.formatted(.currency(code: "IDR")))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.textPrimary)
                                    .hideAmount(if: isHidden)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding()
        .glassCard()
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    var isHidden: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 48, height: 48)
                Text(String(transaction.category.prefix(1)))
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            Text((transaction.type == .income ? "+" : "-") + transaction.amount.formatted(.currency(code: "IDR")))
                .font(.headline)
                .foregroundColor(transaction.type == .income ? .green : .primary)
                .hideAmount(if: isHidden)
        }
        .padding()
        .glassCard()
    }
}
