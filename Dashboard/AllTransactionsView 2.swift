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
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(dataManager.transactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                    .padding()
                    .padding(.bottom, 100) // Space for dock
                }
            }
        }
        .navigationBarHidden(true)
    }
}
