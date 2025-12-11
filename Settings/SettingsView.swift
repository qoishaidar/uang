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
                Section(header: Text("Income")) {
                    ForEach(dataManager.categories.filter { $0.type == .income }) { category in
                        CategoryRow(category: category)
                    }
                    .onDelete { indexSet in
                    }
                }
                
                Section(header: Text("Expense")) {
                    ForEach(dataManager.categories.filter { $0.type == .expense }) { category in
                        CategoryRow(category: category)
                    }
                    .onDelete { indexSet in
                    }
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
                .sheet(isPresented: $showingAddCategory) {
                    AddCategoryView()
                }
            }
        }
    }
}

struct CategoryRow: View {
    let category: Category
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .frame(width: 24)
                .foregroundColor(Theme.textPrimary)
            Text(category.name)
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .listRowBackground(Theme.cardBackground)
    }
}

struct AddCategoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager = DataManager.shared
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "tag"
    @State private var type: Category.TransactionType = .expense
    
    let icons = [
        "tag", "cart", "creditcard", "banknote", "bag", "gift", "house", "car", "tram", "airplane",
        "fork.knife", "cup.and.saucer", "tshirt", "cross.case", "pills", "heart", "star", "bolt",
        "drop", "flame", "leaf", "pawprint", "gamecontroller", "tv", "desktopcomputer", "headphones",
        "book", "graduationcap", "briefcase", "hammer", "wrench", "screwdriver", "gear", "scissors",
        "paintbrush", "bandage", "cross", "bed.double", "sun.max", "moon", "cloud", "umbrella",
        "snowflake", "wind", "music.note", "mic", "video", "camera", "phone", "envelope", "bubble.left",
        "mappin", "location", "clock", "calendar", "bell", "lock", "key", "shield", "flag"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Category Details")) {
                        TextField("Name", text: $name)
                        
                        Picker("Type", selection: $type) {
                            Text("Expense").tag(Category.TransactionType.expense)
                            Text("Income").tag(Category.TransactionType.income)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section(header: Text("Icon")) {
                        IconGridView(selectedIcon: $selectedIcon, icons: icons)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Category")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveCategory()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveCategory() {
        let newCategory = Category(
            id: UUID().uuidString,
            name: name,
            type: type,
            icon: selectedIcon,
            group: nil
        )
        
        Task {
            await dataManager.addCategory(newCategory)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct IconGridView: View {
    @Binding var selectedIcon: String
    let icons: [String]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 15) {
            ForEach(icons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(selectedIcon == icon ? Theme.primary : Theme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(selectedIcon == icon ? Theme.primary.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedIcon = icon
                    }
            }
        }
        .padding(.vertical)
    }
}
