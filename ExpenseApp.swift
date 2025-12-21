import SwiftUI

@main
struct ExpenseApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isActive = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .preferredColorScheme(themeManager.currentTheme.colorScheme)
                    .opacity(isActive ? 1 : 0)
                    .zIndex(0)
                
                if !isActive {
                    SplashScreenView()
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                                .combined(with: .scale(scale: 1.1))
                        ))
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct SplashScreenView: View {
    @State private var size = 0.8
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .cornerRadius(22)
                        .shadow(color: Theme.primary.opacity(0.15), radius: 15, x: 0, y: 8)
                }
                .scaleEffect(size)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("from")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary.opacity(0.6))
                    
                    Text("qois")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.primary)
                        .tracking(1.2)
                        .textCase(.uppercase)
                }
                .padding(.bottom, 30)
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.size = 1.0
                    self.opacity = 1.0
                }
            }
        }
    }
}
