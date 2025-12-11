import SwiftUI

struct ContentView: View {
    @State private var selectedTab: CustomDockView.Tab = .dashboard
    @State private var isDockVisible = true
    @State private var hideDockTask: DispatchWorkItem?
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
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
        .onChange(of: selectedTab) { _ in
            showDock()
        }
        .onAppear {
            scheduleHideDock()
        }
    }
    
    private func showDock() {
        // Cancel existing task
        hideDockTask?.cancel()
        
        // Show dock immediately
        withAnimation {
            isDockVisible = true
        }
        
        // Schedule new hide task
        scheduleHideDock()
    }
    
    private func scheduleHideDock() {
        let task = DispatchWorkItem {
            withAnimation {
                isDockVisible = false
            }
        }
        hideDockTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: task)
    }
}
