import SwiftUI

struct AssetListView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var assetToEdit: Asset?
    @State private var assetToDelete: Asset?
    @State private var showingDeleteAlert = false
    @State private var showingAddAsset = false
    @State private var selectedAsset: Asset?
    
    var totalAssetValue: Double {
        dataManager.assets.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 24) {
                        HStack {
                            Text("Assets")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textPrimary)
                            Spacer()

                            Button(action: { showingAddAsset = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        .padding(.horizontal)
                        
                        ZStack {

                            RoundedRectangle(cornerRadius: 24)
                                .fill(Theme.cardBackground)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            

                            HStack {
                                Spacer()
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 120))
                                    .foregroundColor(Theme.textPrimary.opacity(0.03))
                                    .rotationEffect(.degrees(-15))
                                    .offset(x: 30, y: 30)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "chart.pie.fill")
                                        .foregroundColor(Theme.textPrimary)
                                        .font(.system(size: 20))
                                        .padding(10)
                                        .background(Theme.textPrimary.opacity(0.05))
                                        .clipShape(Circle())
                                    
                                    Text("TOTAL ASSETS")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .tracking(2)
                                        .foregroundColor(Theme.textSecondary)
                                    
                                    Spacer()
                                }
                                
                                Spacer()
                                
                                Text(totalAssetValue.formatted(.currency(code: "IDR")))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                    .hideAmount(if: dataManager.isAmountHidden)
                            }
                            .padding(24)
                        }
                        .frame(height: 160)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    .padding(.bottom, 16)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Theme.textSecondary.opacity(0.0),
                                    Theme.textSecondary.opacity(0.3),
                                    Theme.textSecondary.opacity(0.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(dataManager.assets) { asset in
                            ZStack {
                                Button {
                                    selectedAsset = asset
                                } label: {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                BankCardView(
                                    name: asset.name,
                                    balance: asset.value,
                                    color: "#1E1E1E",
                                    last4: asset.symbol,
                                    type: asset.type,
                                    isHidden: dataManager.isAmountHidden
                                )
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .contextMenu {
                                Button {
                                    assetToEdit = asset
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    assetToDelete = asset
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onMove(perform: moveAssets)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddAsset) {
                AddAssetView()
            }
            .sheet(item: $assetToEdit) { asset in
                EditAssetView(asset: asset)
            }
            .sheet(item: $selectedAsset) { asset in
                NavigationView {
                    AssetDetailView(asset: asset)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    selectedAsset = nil
                                }
                            }
                        }
                }
            }
            .alert("Delete Asset", isPresented: $showingDeleteAlert, presenting: assetToDelete) { asset in
                Button("Delete", role: .destructive) {
                    Task {
                        await dataManager.deleteAsset(id: asset.id!)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { asset in
                Text("Are you sure you want to delete \(asset.name)? This action cannot be undone.")
            }
        }
    }
    
    private func moveAssets(from source: IndexSet, to destination: Int) {
        var updatedAssets = dataManager.assets
        updatedAssets.move(fromOffsets: source, toOffset: destination)
        Task {
            await dataManager.reorderAssets(updatedAssets)
        }
    }
}

struct EditAssetView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager = DataManager.shared
    
    let asset: Asset
    
    @State private var name: String
    @State private var type: String
    
    let types = ["Bank", "E-Wallet", "Cash", "Credit Card"]
    
    init(asset: Asset) {
        self.asset = asset
        _name = State(initialValue: asset.name)
        _type = State(initialValue: asset.type)
    }
    
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
            .navigationTitle("Edit Asset")
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
        var updatedAsset = asset
        updatedAsset.name = name
        updatedAsset.type = type
        updatedAsset.symbol = name.prefix(3).uppercased()
        Task {
            await dataManager.updateAsset(updatedAsset)
            presentationMode.wrappedValue.dismiss()
        }
    }
}
