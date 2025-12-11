import SwiftUI

@main
struct ExpenseApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }
}
