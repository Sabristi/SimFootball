import SwiftUI

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .frame(width: 30) // Largeur fixe pour aligner les textes
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !isDisabled {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .opacity(0.5)
                }
            }
            .padding()
            .foregroundColor(.white)
            .background(
                isDisabled ? Color.gray.opacity(0.3) : color.opacity(0.8)
            )
            .cornerRadius(12)
            // Petit effet de bordure style "Football Manager"
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .disabled(isDisabled)
        .padding(.horizontal)
    }
}
