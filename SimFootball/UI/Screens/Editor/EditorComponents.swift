import SwiftUI

// 1. Les Onglets de l'Éditeur
enum EditorTab: String, CaseIterable {
    case confederations = "Confederations"
    case countries = "Countries"
    case stadiums = "Stadiums"
    case clubs = "Clubs" // <--- NOUVEAU
    
    var icon: String {
        switch self {
        case .confederations: return "globe.desk.fill"
        case .countries: return "flag.fill"
        case .stadiums: return "sportscourt.fill"
        case .clubs: return "shield.checkerboard" // <--- NOUVEAU
        }
    }
}

// 2. Le Header de l'Éditeur
struct EditorHeader: View {
    let title: String
    let onBack: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            
            // BOUTON RETOUR
            Button(action: onBack) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(.leading, 10)
            
            // TITRE
            HStack(spacing: 8) {
                Rectangle().fill(Color.purple).frame(width: 3, height: 18).cornerRadius(2)
                Text("DB EDITOR : \(title.uppercased())")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundColor(.white)
            }
            .padding(.leading, 15)
            
            Spacer()
            
            // BOUTON SAVE
            Button(action: onSave) {
                HStack(spacing: 6) {
                    Image(systemName: "externaldrive.fill")
                    Text("SAVE DB")
                        .fontWeight(.bold)
                }
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.purple)
                .cornerRadius(20)
                .shadow(color: .purple.opacity(0.5), radius: 5)
            }
            .padding(.trailing, 10)
        }
        .frame(height: 55)
        .background(
            LinearGradient(colors: [Color.black.opacity(0.9), Color.black.opacity(0.0)], startPoint: .top, endPoint: .bottom)
        )
    }
}

// 3. La Sidebar de l'Éditeur
struct EditorSidebar: View {
    @Binding var selectedTab: EditorTab
    
    var body: some View {
        VStack(spacing: 15) {
            Color.clear.frame(height: 10)
            
            ForEach(EditorTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation { selectedTab = tab }
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == tab {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .blur(radius: 5)
                            }
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == tab ? .purple : .gray)
                        }
                        Text(tab.rawValue)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                    }
                    .frame(width: 60, height: 55)
                    .background(selectedTab == tab ? Color.white.opacity(0.05) : Color.clear)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.6).background(.ultraThinMaterial))
        .overlay(Rectangle().frame(width: 1).foregroundColor(.white.opacity(0.1)), alignment: .trailing)
    }
}
