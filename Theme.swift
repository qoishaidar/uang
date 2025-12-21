import SwiftUI

struct Theme {
    static let background = Color(uiColor: .systemBackground)
    static let cardBackground = Color(uiColor: .secondarySystemBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let primary = Color.blue
    
    static let chartColors: [Color] = [
        Color(hex: "6366f1"), // Indigo
        Color(hex: "10b981"), // Emerald
        Color(hex: "f59e0b"), // Amber
        Color(hex: "f43f5e"), // Rose
        Color(hex: "06b6d4"), // Cyan
        Color(hex: "8b5cf6"), // Violet
        Color(hex: "f97316"), // Orange
        Color(hex: "14b8a6"), // Teal
        Color(hex: "3b82f6"), // Blue
        Color(hex: "ec4899")  // Pink
    ]
    
    static func glassMaterial() -> Material {
        return .ultraThinMaterial
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        let scanner = Scanner(string: hex)
        scanner.scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.glassMaterial())
            .cornerRadius(24)
            .shadow(color: Color.primary.opacity(0.05), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(GlassCard())
    }
}

struct HideAmountModifier: ViewModifier {
    var isHidden: Bool
    
    func body(content: Content) -> some View {
        if isHidden {
            Text("••••••")
                .font(.system(.body, design: .monospaced))
                .redacted(reason: .placeholder)
        } else {
            content
        }
    }
}

extension View {
    func hideAmount(if isHidden: Bool) -> some View {
        modifier(HideAmountModifier(isHidden: isHidden))
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
