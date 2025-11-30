import SwiftUI

struct MainGameHeader: View {
    let title: String
    let icon: String
    let currentDate: Date
    let onBack: () -> Void
    let onContinue: () -> Void
    let onCalendarClick: () -> Void // <--- NOUVEAU PARAMÈTRE
    
    var body: some View {
        HStack(spacing: 0) {
            
            // BOUTON RETOUR
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(.leading, 10)
            
            // TITRE
            HStack(spacing: 8) {
                Rectangle().fill(Color.green).frame(width: 3, height: 18).cornerRadius(2)
                Text(title.uppercased())
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundColor(.white)
            }
            .padding(.leading, 15)
            
            Spacer()
            
            // BLOC DATE + CONTINUE
            HStack(spacing: 10) {
                
                // DATE DISPLAY (Maintenant un Bouton)
                Button(action: onCalendarClick) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.green) // Vert pour inciter au clic
                        
                        Text(currentDate.formatted(.dateTime.weekday(.abbreviated).day().month().year()))
                            .font(.system(size: 12, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle()) // Pour garder l'aspect custom
                
                // BOUTON CONTINUE
                Button(action: onContinue) {
                    HStack(spacing: 4) {
                        Text("CONTINUE")
                            .font(.system(size: 12, weight: .black))
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(LinearGradient(colors: [Color.green, Color.green.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    .cornerRadius(20)
                }
            }
            .padding(.trailing, 10)
        }
        .frame(height: 55)
        .background(
            LinearGradient(colors: [Color.black.opacity(0.9), Color.black.opacity(0.0)], startPoint: .top, endPoint: .bottom)
        )
    }
}
