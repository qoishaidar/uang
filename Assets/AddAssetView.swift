import SwiftUI

struct AddAssetView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager = DataManager.shared
    
    @State private var name: String = ""
    @State private var type: String = "Bank"
    let types = ["Bank", "E-Wallet", "Cash", "Credit Card"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Details")) {
                        TextField("Asset Name", text: $name)
                        Picker("Type", selection: $type) {
                            ForEach(types, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Asset")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveAsset()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveAsset() {
        let asset = Asset(
            id: nil,
            name: name,
            symbol: name.prefix(3).uppercased(),
            value: 0.0,
            change: 0.0,
            type: type,
            sortOrder: 0
        )
        
        Task {
            await dataManager.addAsset(asset)
            presentationMode.wrappedValue.dismiss()
        }
    }
}
