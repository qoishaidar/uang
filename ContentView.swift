import SwiftUI

struct ContentView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTab: CustomDockView.Tab = .dashboard
    @State private var isDockVisible = true
    @State private var hideDockTask: DispatchWorkItem?
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView(isDockVisible: isDockVisible)
                    .tag(CustomDockView.Tab.dashboard)
                
                WalletListView()
                    .tag(CustomDockView.Tab.wallets)
                
                AssetListView()
                    .tag(CustomDockView.Tab.assets)
                
                SettingsView()
                    .tag(CustomDockView.Tab.settings)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            CustomDockView(selectedTab: $selectedTab)
                .offset(y: isDockVisible ? 0 : 150)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isDockVisible)
        }
        .ignoresSafeArea(.keyboard)
        .ignoresSafeArea(.container, edges: .bottom)
        .onChange(of: selectedTab) {
            showDock()
        }
        .onAppear {
            updateDockVisibility()
        }
        .onChange(of: themeManager.dockBehavior) { _ in
            updateDockVisibility()
        }
    }
    
    private func showDock() {
        hideDockTask?.cancel()
        
        switch themeManager.dockBehavior {
        case .auto:
            withAnimation { isDockVisible = true }
            scheduleHideDock()
        case .show:
            withAnimation { isDockVisible = true }
        case .hide:
            withAnimation { isDockVisible = false }
        }
    }
    
    private func scheduleHideDock() {
        guard themeManager.dockBehavior == .auto else { return }
        
        let task = DispatchWorkItem {
            withAnimation {
                isDockVisible = false
            }
        }
        hideDockTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: task)
    }
    
    private func updateDockVisibility() {
        hideDockTask?.cancel()
        
        switch themeManager.dockBehavior {
        case .auto:
            isDockVisible = true
            scheduleHideDock()
        case .show:
            withAnimation { isDockVisible = true }
        case .hide:
            withAnimation { isDockVisible = false }
        }
    }
}
