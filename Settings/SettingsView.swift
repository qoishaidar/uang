import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showingAddCategory = false
    @State private var showingCategories = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                List {
                    Section(header: Text("General").foregroundColor(Theme.textSecondary)) {
                        Button(action: { showingCategories = true }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(Theme.textPrimary)
                                Text("Manage Categories")
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        .listRowBackground(Theme.cardBackground)
                        .sheet(isPresented: $showingCategories) {
                            NavigationView {
                                CategoriesListView()
                            }
                        }
                    }
                    
                    Section(header: Text("Appearance").foregroundColor(Theme.textSecondary), footer: 
                        HStack {
                            Spacer()
                            Text("app by qois")
                                .font(.footnote)
                                .foregroundColor(Theme.textSecondary)
                                .padding(.top, 20)
                            Spacer()
                        }
                    ) {
                        Picker("Theme", selection: $themeManager.currentTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(.menu)
                        .listRowBackground(Theme.cardBackground)
                        
                        Picker("Dock Systems", selection: $themeManager.dockBehavior) {
                            ForEach(DockBehavior.allCases) { behavior in
                                Text(behavior.rawValue).tag(behavior)
                            }
                        }
                        .pickerStyle(.menu)
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
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingAddCategory = false
    @State private var selectedCategory: Category?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: Category?
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            List {
                Section(header: 
                    HStack {
                        Text("Income")
                        Spacer()
                        Button(action: {
                            withAnimation {
                                if editMode == .active {
                                    editMode = .inactive
                                } else {
                                    editMode = .active
                                }
                            }
                        }) {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(Theme.primary)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                ) {
                    ForEach(dataManager.categories.filter { $0.type == .income }) { category in
                        Button(action: {
                            if editMode == .inactive {
                                selectedCategory = category
                            }
                        }) {
                            CategoryRow(category: category)
                        }
                        .disabled(editMode == .active)
                    }
                    .onDelete { indexSet in
                        confirmDelete(at: indexSet, type: .income)
                    }
                    .onMove { indices, newOffset in
                        moveCategory(from: indices, to: newOffset, type: .income)
                    }
                }
                
                Section(header: Text("Expense")) {
                    ForEach(dataManager.categories.filter { $0.type == .expense }) { category in
                        Button(action: {
                            if editMode == .inactive {
                                selectedCategory = category
                            }
                        }) {
                            CategoryRow(category: category)
                        }
                        .disabled(editMode == .active)
                    }
                    .onDelete { indexSet in
                        confirmDelete(at: indexSet, type: .expense)
                    }
                    .onMove { indices, newOffset in
                        moveCategory(from: indices, to: newOffset, type: .expense)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .environment(\.editMode, $editMode)
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Category?"),
                    message: Text("Are you sure you want to delete this category? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let category = categoryToDelete {
                            Task {
                                await dataManager.deleteCategory(id: category.id)
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { 
                    selectedCategory = nil
                    showingAddCategory = true 
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(categoryToEdit: nil)
        }
        .sheet(item: $selectedCategory) { category in
            AddCategoryView(categoryToEdit: category)
        }
        .onAppear {
            Task {
                await dataManager.fetchData()
            }
        }
    }
    
    private func confirmDelete(at offsets: IndexSet, type: Category.TransactionType) {
        let filteredCategories = dataManager.categories.filter { $0.type == type }
        if let index = offsets.first {
            categoryToDelete = filteredCategories[index]
            showingDeleteAlert = true
        }
    }
    
    private func moveCategory(from source: IndexSet, to destination: Int, type: Category.TransactionType) {
        var filteredCategories = dataManager.categories.filter { $0.type == type }
        filteredCategories.move(fromOffsets: source, toOffset: destination)
        
        let incomeCategories = type == .income ? filteredCategories : dataManager.categories.filter { $0.type == .income }
        let expenseCategories = type == .expense ? filteredCategories : dataManager.categories.filter { $0.type == .expense }
        
        let allCategories = incomeCategories + expenseCategories
        
        Task {
            await dataManager.reorderCategories(allCategories)
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
        .contentShape(Rectangle())
        .listRowBackground(Theme.cardBackground)
    }
}

struct AddCategoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager = DataManager.shared
    
    var categoryToEdit: Category?
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "tag"
    @State private var type: Category.TransactionType = .expense
    
    init(categoryToEdit: Category? = nil) {
        self.categoryToEdit = categoryToEdit
        _name = State(initialValue: categoryToEdit?.name ?? "")
        _selectedIcon = State(initialValue: categoryToEdit?.icon ?? "tag")
        _type = State(initialValue: categoryToEdit?.type ?? .expense)
    }
    
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
            .navigationTitle(categoryToEdit == nil ? "New Category" : "Edit Category")
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
        if let category = categoryToEdit {
            let updatedCategory = Category(
                id: category.id,
                name: name,
                type: type,
                icon: selectedIcon,
                group: category.group
            )
            Task {
                await dataManager.updateCategory(updatedCategory)
                presentationMode.wrappedValue.dismiss()
            }
        } else {
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
