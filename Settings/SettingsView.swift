import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingAddCategory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                List {
                    Section(header: Text("General").foregroundColor(Theme.textSecondary)) {
                        NavigationLink(destination: CategoriesListView()) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(Theme.textPrimary)
                                Text("Manage Categories")
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        .listRowBackground(Theme.cardBackground)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
                .navigationTitle("Settings")
            }
        }
    }
}

struct CategoriesListView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingAddCategory = false
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            List {
                ForEach(dataManager.categories) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .frame(width: 24)
                        Text(category.name)
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text(category.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.cardBackground)
                            .cornerRadius(8)
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .onDelete { indexSet in
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCategory = true }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}
