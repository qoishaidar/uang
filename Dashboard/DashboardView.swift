import SwiftUI
import Charts
import UIKit

struct DashboardView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingAddTransaction = false
    var isDockVisible: Bool = true
    
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
                        
                        TotalBalanceCard(balance: dataManager.totalBalance, income: dataManager.totalIncome, expense: dataManager.totalExpense, isHidden: dataManager.isAmountHidden)
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
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                            showingAddTransaction = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(Theme.primary))
                                .shadow(color: Theme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(ScaleButtonStyle())
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
    @State private var selectedTimeFilter: TimeFilter = .all
    @State private var selectedCategory: CategoryDetail?
    
    enum TimeFilter: String, CaseIterable, Identifiable {
        case day = "Day"
        case month = "Month"
        case year = "Year"
        case all = "All"
        
        var id: String { self.rawValue }
    }
    
    var aggregatedExpenses: [(category: String, amount: Double, color: Color)] {
        let filteredTransactions = transactions.filter { transaction in
            guard transaction.type == .expense else { return false }
            
            let calendar = Calendar.current
            let now = Date()
            
            switch selectedTimeFilter {
            case .day:
                return calendar.isDateInToday(transaction.date)
            case .month:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .year)
            case .all:
                return true
            }
        }
        
        let grouped = Dictionary(grouping: filteredTransactions, by: { $0.category })
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
            HStack {
                Text("Expenses Breakdown")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Menu {
                    ForEach(TimeFilter.allCases) { filter in
                        Button(action: {
                            withAnimation {
                                selectedTimeFilter = filter
                            }
                        }) {
                            HStack {
                                Text(filter.rawValue)
                                if selectedTimeFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedTimeFilter.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.primary.opacity(0.1))
                    .cornerRadius(20)
                }
            }
            
            if aggregatedExpenses.isEmpty {
                Text("No expenses for this period")
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
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCategory = CategoryDetail(name: item.category)
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
        .sheet(item: $selectedCategory) { detail in
            CategoryTransactionsView(
                category: detail.name,
                transactions: transactions,
                timeFilter: selectedTimeFilter,
                isHidden: isHidden
            )
        }
    }
}

struct CategoryDetail: Identifiable {
    let id = UUID()
    let name: String
}

struct CategoryTransactionsView: View {
    let category: String
    let transactions: [Transaction]
    let timeFilter: ExpenseChartView.TimeFilter
    let isHidden: Bool
    @Environment(\.dismiss) var dismiss
    
    var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            guard transaction.category == category, transaction.type == .expense else { return false }
            
            let calendar = Calendar.current
            let now = Date()
            
            switch timeFilter {
            case .day:
                return calendar.isDateInToday(transaction.date)
            case .month:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .year)
            case .all:
                return true
            }
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if filteredTransactions.isEmpty {
                    Text("No transactions found")
                        .foregroundColor(Theme.textSecondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredTransactions) { transaction in
                                TransactionRow(transaction: transaction, isHidden: isHidden)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(category)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
