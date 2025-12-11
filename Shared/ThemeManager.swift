import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .system
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = ThemeManager()
    
    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        }
        
        $currentTheme
            .dropFirst()
            .sink { theme in
                UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
            }
            .store(in: &cancellables)
    }
}
