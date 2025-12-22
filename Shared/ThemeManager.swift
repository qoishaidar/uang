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

enum DockBehavior: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case show = "Always Show"
    case hide = "Always Hide"
    
    var id: String { self.rawValue }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .system
    @Published var dockBehavior: DockBehavior = .auto
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = ThemeManager()
    
    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        }
        
        if let savedDock = UserDefaults.standard.string(forKey: "dockBehavior"),
           let dock = DockBehavior(rawValue: savedDock) {
            self.dockBehavior = dock
        }
        
        $currentTheme
            .dropFirst()
            .sink { theme in
                UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
            }
            .store(in: &cancellables)
        
        $dockBehavior
            .dropFirst()
            .sink { behavior in
                UserDefaults.standard.set(behavior.rawValue, forKey: "dockBehavior")
            }
            .store(in: &cancellables)
    }
}
