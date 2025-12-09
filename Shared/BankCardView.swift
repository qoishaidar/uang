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
            GeometryReader { proxy in
                ZStack {
                    Color(hex: color)
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05),
                            Color.clear,
                            Color.black.opacity(0.1),
                            Color.white.opacity(0.05)
                        ]),
                        center: .center,
                        angle: .degrees(45)
                    )
                    .blur(radius: 10)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .blendMode(.overlay)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color(hex: color).opacity(0.3), radius: 8, x: 0, y: 4)
            
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(balance.formatted(.currency(code: "IDR")))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        .hideAmount(if: isHidden)
                }
                
                Spacer()
                
                Text(type)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(height: 100)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
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
