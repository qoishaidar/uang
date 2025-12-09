import SwiftUI

struct WalletListView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var walletToEdit: Wallet?
    @State private var walletToDelete: Wallet?
    @State private var showingDeleteAlert = false
    @State private var showingAddWallet = false
    
    var totalWalletBalance: Double {
        dataManager.wallets.reduce(0) { $0 + $1.balance }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 24) {
                        HStack {
                            Text("Wallets")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            EditButton()
                                .padding(.trailing, 8)
                            Button(action: { showingAddWallet = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("Total Balance")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                            Text(totalWalletBalance.formatted(.currency(code: "IDR")))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                                .hideAmount(if: dataManager.isAmountHidden)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .glassCard()
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    .padding(.bottom, 16)
                    
                    List {
                        ForEach(dataManager.wallets) { wallet in
                            ZStack {
                                NavigationLink(destination: WalletDetailView(wallet: wallet)) {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                BankCardView(
                                    name: wallet.name,
                                    balance: wallet.balance,
                                    color: "#1E1E1E",
                                    last4: wallet.last4,
                                    type: wallet.type,
                                    isHidden: dataManager.isAmountHidden
                                )
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .contextMenu {
                                Button {
                                    walletToEdit = wallet
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    walletToDelete = wallet
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    walletToDelete = wallet
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    walletToEdit = wallet
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .onMove(perform: moveWallets)
                        .onDelete(perform: deleteWallet)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddWallet) {
                AddWalletView()
            }
            .sheet(item: $walletToEdit) { wallet in
                EditWalletView(wallet: wallet)
            }
            .alert("Delete Wallet", isPresented: $showingDeleteAlert, presenting: walletToDelete) { wallet in
                Button("Delete", role: .destructive) {
                    Task {
                        await dataManager.deleteWallet(id: wallet.id!)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { wallet in
                Text("Are you sure you want to delete \(wallet.name)? This action cannot be undone.")
            }
        }
    }
    
    private func moveWallets(from source: IndexSet, to destination: Int) {
        var updatedWallets = dataManager.wallets
        updatedWallets.move(fromOffsets: source, toOffset: destination)
        Task {
            await dataManager.reorderWallets(updatedWallets)
        }
    }
    
    private func deleteWallet(at offsets: IndexSet) {
        for index in offsets {
            let wallet = dataManager.wallets[index]
            Task {
                await dataManager.deleteWallet(id: wallet.id!)
            }
        }
    }
}

struct EditWalletView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager = DataManager.shared
    
    let wallet: Wallet
    
    @State private var name: String
    @State private var type: String
    @State private var color: String
    
    let types = ["Bank", "E-Wallet", "Cash", "Credit Card"]
    let colors = ["#000000", "#1E1E1E", "#0047AB", "#228B22", "#FF4500", "#800080"]
    
    init(wallet: Wallet) {
        self.wallet = wallet
        _name = State(initialValue: wallet.name)
        _type = State(initialValue: wallet.type)
        _color = State(initialValue: wallet.color)
    }
    
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
            .navigationTitle("Edit Wallet")
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
        var updatedWallet = wallet
        updatedWallet.name = name
        updatedWallet.type = type
        updatedWallet.type = type
        updatedWallet.color = color
        
        Task {
            await dataManager.updateWallet(updatedWallet)
            presentationMode.wrappedValue.dismiss()
        }
    }
}
