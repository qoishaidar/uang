import SwiftUI

struct AllTransactionsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Theme.textPrimary)
                    }
                    
                    Text("All Transactions")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                    
                    // Invisible button for balance
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.clear)
                }
                .padding()
                .background(Theme.background)
                
                List {
                    ForEach(dataManager.transactions) { transaction in
                        TransactionRow(transaction: transaction, isHidden: dataManager.isAmountHidden)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                let transaction = dataManager.transactions[index]
                                await dataManager.deleteTransaction(id: transaction.id!)
                            }
                        }
                    }
                    
                    Color.clear
                        .frame(height: 140)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                .listStyle(.plain)
                .refreshable {
                    await dataManager.fetchData()
                }
            }
        }
        .navigationBarHidden(true)
        .simultaneousGesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
    }
}
