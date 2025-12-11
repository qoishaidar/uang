import SwiftUI

struct Theme {
    static let background = Color(uiColor: .systemBackground)
    static let cardBackground = Color(uiColor: .secondarySystemBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let primary = Color.blue
    
    static func glassMaterial() -> Material {
        return .ultraThinMaterial
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
