import SwiftUI

struct ContentView: View {
    @State private var selectedTab: CustomDockView.Tab = .dashboard
    
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
        }
        .ignoresSafeArea(.keyboard)
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
