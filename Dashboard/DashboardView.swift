import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingAddTransaction = false
    var isDockVisible: Bool = true
    
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
                            
                        }
                        .padding(.horizontal)
                        
                        TotalBalanceCard(balance: totalBalance, income: income, expense: expense, isHidden: dataManager.isAmountHidden)
                            .padding(.horizontal)
                            .onTapGesture {
                                withAnimation {
                                    dataManager.isAmountHidden.toggle()
                                }
                            }
                        
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
                                        .font(.subheadline)
                                        .foregroundColor(Theme.primary)
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
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddTransaction = true }) {
                            Image(systemName: "plus")
                                .font(.title.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(Theme.primary))
                                .shadow(color: Theme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, isDockVisible ? 90 : 30)
                        .animation(.spring(), value: isDockVisible)
                    }
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
    
    var aggregatedExpenses: [(category: String, amount: Double, color: Color)] {
        let expenses = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        let sorted = grouped.map { category, transactions in
            (category: category, amount: abs(transactions.reduce(0) { $0 + $1.amount }))
        }.sorted { $0.amount > $1.amount }
        
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow, .red, .cyan, .mint, .indigo]
        
        return sorted.enumerated().map { index, item in
            (category: item.category, amount: item.amount, color: colors[index % colors.count])
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Expenses Breakdown")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            
            if aggregatedExpenses.isEmpty {
                Text("No expenses yet")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(aggregatedExpenses, id: \.category) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .cornerRadius(5)
                    .foregroundStyle(item.color)
                }
                .frame(height: 220)
                
                if !aggregatedExpenses.isEmpty {
                    Divider()
                        .background(Color.primary.opacity(0.2))
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showDetails.toggle()
                        }
                    }) {
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
                        VStack(spacing: 16) {
                            ForEach(aggregatedExpenses, id: \.category) { item in
                                HStack {
                                        Image(systemName: DataManager.shared.getCategoryIcon(for: item.category))
                                        .foregroundColor(item.color)
                                        .font(.subheadline)
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
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }
                }
            }
        }
        .padding(24)
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
                Image(systemName: DataManager.shared.getCategoryIcon(for: transaction.category))
                    .font(.title2)
                    .foregroundColor(Theme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("\(transaction.date.formatted(date: .abbreviated, time: .omitted)) • \(transaction.title)")
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
