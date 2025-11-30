import SwiftUI

struct BentoCard: View {
    var title: String
    var subtitle: String? = nil
    var icon: String
    var color: Color
    var isHero: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // 1. FOND
                RoundedRectangle(cornerRadius: 20) // Coins un peu moins ronds
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
                
                // 2. CONTENU
                HStack(alignment: .center, spacing: 15) {
                    // Icone à gauche
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.headline)
                    }
                    
                    // Textes
                    // Textes
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8) // <--- AJOUTE CETTE LIGNE
                                            
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    
                    // Petite flèche discrète à droite
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(16) // <--- MARGE RÉDUITE ICI (C'était 24 avant)
            }
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

// (Garde le BouncyButtonStyle s'il est déjà dans un autre fichier, sinon ajoute-le ici)
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
