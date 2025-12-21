import SwiftUI

struct BankCardView: View {
    let name: String
    let balance: Double
    let color: String
    let last4: String
    let type: String
    var isHidden: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                    
                    Text(balance.formatted(.currency(code: "IDR")))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .hideAmount(if: isHidden)
                }
                
                Spacer()
                
                Text(type)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.primary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(height: 100)
        .glassCard()
    }
}

