import SwiftUI

struct CustomDockView: View {
    @Binding var selectedTab: Tab
    
    enum Tab: String, CaseIterable {
        case dashboard = "square.grid.2x2.fill"
        case wallets = "creditcard.fill"
        case assets = "chart.line.uptrend.xyaxis"
        case settings = "gearshape.fill"
        
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .wallets: return "Wallets"
            case .assets: return "Assets"
            case .settings: return "Settings"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 25) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.rawValue)
                            .font(.system(size: 24))
                            .scaleEffect(selectedTab == tab ? 1.2 : 1.0)
                        
                        if selectedTab == tab {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                                .matchedGeometryEffect(id: "dot", in: namespace)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .foregroundColor(selectedTab == tab ? .white : .gray)
                    .frame(width: 50, height: 50)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.bottom, 30)
    }
    
    @Namespace private var namespace
}
