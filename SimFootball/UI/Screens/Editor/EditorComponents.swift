import SwiftUI

// MARK: - 1. Les Onglets de l'Éditeur
enum EditorTab: String, CaseIterable {
    case confederations = "Confederations"
    case countries = "Countries"
    case stadiums = "Stadiums"
    case clubs = "Clubs" // ✅ NOUVEAU : Onglet Clubs
    
    var icon: String {
        switch self {
        case .confederations: return "globe.desk.fill"
        case .countries: return "flag.fill"
        case .stadiums: return "sportscourt.fill"
        case .clubs: return "tshirt.fill" // Icone plus représentative pour les kits/clubs
        }
    }
}

// MARK: - 2. Le Header de l'Éditeur
struct EditorHeader: View {
    let title: String
    let onBack: () -> Void
    let onSave: () -> Void      // Action pour sauvegarder dans le simulateur
    let onCopyJSON: () -> Void  // ✅ NOUVEAU : Action pour copier le JSON
    
    var body: some View {
        HStack(spacing: 0) {
            
            // --- GAUCHE : BOUTON RETOUR ---
            Button(action: onBack) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(.leading, 10)
            .buttonStyle(.plain)
            
            // --- CENTRE : TITRE ---
            HStack(spacing: 8) {
                Rectangle().fill(Color.purple).frame(width: 3, height: 18).cornerRadius(2)
                Text("DB EDITOR : \(title.uppercased())")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundColor(.white)
            }
            .padding(.leading, 15)
            
            Spacer()
            
            // --- DROITE : ACTIONS ---
            HStack(spacing: 12) {
                
                // BOUTON 1 : SAVE (Simulateur)
                Button(action: onSave) {
                    HStack(spacing: 6) {
                        Image(systemName: "externaldrive.fill")
                        Text("SAVE")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.8))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help("Sauvegarde dans le dossier Documents du Simulateur")
                
                // BOUTON 2 : COPIER JSON (Xcode)
                Button(action: onCopyJSON) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("JSON")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange) // Orange pour bien le distinguer
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help("Copie le JSON complet dans le presse-papier")
            }
            .padding(.trailing, 15)
        }
        .frame(height: 60)
        .background(
            Color.black.opacity(0.8)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}

// MARK: - 3. La Sidebar de l'Éditeur
struct EditorSidebar: View {
    @Binding var selectedTab: EditorTab
    
    var body: some View {
        VStack(spacing: 15) {
            Color.clear.frame(height: 10)
            
            ForEach(EditorTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                }) {
                    VStack(spacing: 6) {
                        ZStack {
                            // Effet de surbrillance si sélectionné
                            if selectedTab == tab {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 38, height: 38)
                                    .blur(radius: 2)
                                
                                Circle()
                                    .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                                    .frame(width: 38, height: 38)
                            }
                            
                            Image(systemName: tab.icon)
                                .font(.system(size: 18))
                                .foregroundColor(selectedTab == tab ? .purple : .gray)
                        }
                        
                        Text(tab.rawValue)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                            .lineLimit(1)
                    }
                    .frame(width: 70, height: 60)
                    .contentShape(Rectangle()) // Rend toute la zone cliquable
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.5)) // Fond légèrement transparent
        .overlay(
            Rectangle().frame(width: 1).foregroundColor(.white.opacity(0.1)),
            alignment: .trailing
        )
    }
}
