import SwiftUI

struct AllTransactionsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
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
            .navigationTitle("All Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }

    }
}
