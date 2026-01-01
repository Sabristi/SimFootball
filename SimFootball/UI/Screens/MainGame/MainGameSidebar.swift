import SwiftUI

struct MainGameSidebar: View {
    @Binding var selectedTab: GameTab
    
    // INFOS DYNAMIQUES
    let unreadCount: Int
    let primaryCountry: Country?
    
    // NOUVEAU : Action au clic sur le pays
    var onPrimaryCountryClick: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            
            // ONGLETS
            Group {
                // INBOX
                InboxSidebarButton(
                    selectedTab: $selectedTab,
                    unreadCount: unreadCount
                )
                
                // HOME
                SidebarButton(tab: .home, selectedTab: $selectedTab)
                
                // BOUTON PAYS (DÉCLENCHE LA POPUP MAINTENANT)
                Button(action: onPrimaryCountryClick) {
                    VStack(spacing: 4) {
                        ZStack {
                            // On ne surligne plus comme un onglet actif, c'est un bouton d'action
                            Circle()
                                .fill(Color.white.opacity(0.05)) // Fond neutre par défaut
                                .frame(width: 40, height: 40)
                            
                            Text(primaryCountry?.flagEmoji ?? "🌍")
                                .font(.system(size: 20))
                        }
                        .frame(width: 40, height: 40)
                        
                        Text(primaryCountry?.name ?? "Nation")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(width: 60, height: 55)
                    .background(Color.clear) // Pas de fond "actif"
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.horizontal, 15)
                
                SidebarButton(tab: .squad, selectedTab: $selectedTab)
                SidebarButton(tab: .scouting, selectedTab: $selectedTab)
                SidebarButton(tab: .world, selectedTab: $selectedTab)
            }
            
            Spacer()
            
            SidebarButton(tab: .settings, selectedTab: $selectedTab)
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(
            Color.black.opacity(0.6)
                .background(.ultraThinMaterial)
        )
        .background(
            Color.black.opacity(0.6)
                .padding(.leading, -50)
                .ignoresSafeArea()
        )
        .overlay(
            Rectangle().frame(width: 1).foregroundColor(.white.opacity(0.1)),
            alignment: .trailing
        )
    }
}

// ... (InboxSidebarButton et SidebarButton inchangés en dessous)
struct InboxSidebarButton: View {
    @Binding var selectedTab: GameTab
    let unreadCount: Int
    
    var isSelected: Bool { selectedTab == .inbox }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = .inbox }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .blur(radius: 5)
                    }
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .green : .gray)
                    
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 10, y: -10)
                            .overlay(
                                Circle().stroke(Color.black, lineWidth: 2)
                                    .offset(x: 10, y: -10)
                            )
                    }
                }
                .frame(width: 40, height: 40)
                
                Text("Inbox")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(width: 60, height: 55)
            .background(isSelected ? Color.white.opacity(0.05) : Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SidebarButton: View {
    let tab: GameTab
    @Binding var selectedTab: GameTab
    
    var isSelected: Bool { selectedTab == tab }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .blur(radius: 5)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .green : .gray)
                }
                .frame(width: 40, height: 40)
                
                Text(tab.rawValue)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(width: 60, height: 55)
            .background(isSelected ? Color.white.opacity(0.05) : Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
