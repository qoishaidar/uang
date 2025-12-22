import SwiftUI

struct WalletListView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var walletToEdit: Wallet?
    @State private var walletToDelete: Wallet?
    @State private var showingDeleteAlert = false
    @State private var showingAddWallet = false
    @State private var selectedWallet: Wallet?
    
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
                            Button(action: { showingAddWallet = true }) {
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
                                Image(systemName: "wallet.pass.fill")
                                    .font(.system(size: 120))
                                    .foregroundColor(Theme.textPrimary.opacity(0.03))
                                    .rotationEffect(.degrees(-15))
                                    .offset(x: 30, y: 30)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "creditcard")
                                        .foregroundColor(Theme.textPrimary)
                                        .font(.system(size: 20))
                                        .padding(10)
                                        .background(Theme.textPrimary.opacity(0.05))
                                        .clipShape(Circle())
                                    
                                    Text("TOTAL BALANCE")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .tracking(2)
                                        .foregroundColor(Theme.textSecondary)
                                    
                                    Spacer()
                                }
                                
                                Spacer()
                                
                                Text(totalWalletBalance.formatted(.currency(code: "IDR")))
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
                        ForEach(dataManager.wallets) { wallet in
                            ZStack {
                                Button {
                                    selectedWallet = wallet
                                } label: {
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
                        }
                        .onMove(perform: moveWallets)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddWallet) {
                AddWalletView()
                    .presentationDetents([.medium])
            }
            .sheet(item: $walletToEdit) { wallet in
                EditWalletView(wallet: wallet)
            }
            .sheet(item: $selectedWallet) { wallet in
                NavigationView {
                    WalletDetailView(wallet: wallet)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    selectedWallet = nil
                                }
                            }
                        }
                }
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
        updatedWallet.color = color
        
        Task {
            await dataManager.updateWallet(updatedWallet)
            presentationMode.wrappedValue.dismiss()
        }
    }
}
