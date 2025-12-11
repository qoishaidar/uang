import SwiftUI

struct AddWalletView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager = DataManager.shared
    
    @State private var name: String = ""
    @State private var type: String = "Bank"
    let types = ["Bank", "E-Wallet", "Cash", "Credit Card"]
    let colors = ["#000000", "#1E1E1E", "#0047AB", "#228B22", "#FF4500", "#800080"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Details")) {
                        TextField("Wallet Name", text: $name)
                        Picker("Type", selection: $type) {
                            ForEach(types, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                    }
                    
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Wallet")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveWallet()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveWallet() {
        let wallet = Wallet(
            id: nil,
            name: name,
            balance: 0.0,
            type: type,
            color: "#1E1E1E",
            last4: "",
            sortOrder: 0
        )
        
        Task {
            await dataManager.addWallet(wallet)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

extension View {
    func maxLength(_ length: Int) -> some View {
        modifier(MaxLengthModifier(maxLength: length))
    }
}

struct MaxLengthModifier: ViewModifier {
    let maxLength: Int
    
    func body(content: Content) -> some View {
        content
    }
}
