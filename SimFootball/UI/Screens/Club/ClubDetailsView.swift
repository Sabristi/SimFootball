//
//  ClubDetailsView.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import SwiftUI

// MARK: - 1. ENUMS (Navigation)

enum ClubTab: String, CaseIterable {
    case overview = "Overview"
    case squad = "Squad"
    case schedule = "Schedule"
    case history = "History"
}

enum ClubOverviewSubTab: String, CaseIterable, Identifiable {
    case profile = "Profile"
    case general = "General"
    var id: String { rawValue }
}

enum ClubSquadSubTab: String, CaseIterable, Identifiable {
    case players = "Players"
    case tactic = "Tactic"
    var id: String { rawValue }
}

// MARK: - 2. VUE PRINCIPALE

struct ClubDetailsView: View {
    let clubId: String
    let seasonId: String // Utile pour filtrer le calendrier ou les stats de la saison
    
    // États de navigation
    @State private var selectedOverviewSubTab: ClubOverviewSubTab = .profile
    @State private var selectedSquadSubTab: ClubSquadSubTab = .players
    
    @Binding var selectedTab: ClubTab
        
    
    // Accès aux données
    var club: Club? {
        GameDatabase.shared.getClub(byId: clubId)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. BARRE D'ONGLETS
            HStack(spacing: 0) {
                ForEach(ClubTab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .background(Color.black.opacity(0.6))
            
            // 2. CONTENU
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: "121212")) // Fond sombre global
    }
    
    // MARK: - LOGIQUE DES ONGLETS
    
    @ViewBuilder
    private func tabButton(for tab: ClubTab) -> some View {
        // Style commun pour le texte
        let isSelected = selectedTab == tab
        let textColor = isSelected ? Color.yellow : Color.gray
        
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                
                // 1. Logique pour OVERVIEW (Menu)
                if tab == .overview {
                    Button(action: {
                        selectedTab = .overview
                        selectedOverviewSubTab = .profile // Reset par défaut
                    }) {
                        Text(tab.rawValue.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(textColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Menu {
                        ForEach(ClubOverviewSubTab.allCases) { sub in
                            Button(sub.rawValue) {
                                selectedTab = .overview
                                selectedOverviewSubTab = sub
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(textColor)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .menuIndicator(.hidden)
                }
                
                // 2. Logique pour SQUAD (Menu)
                else if tab == .squad {
                    Button(action: {
                        selectedTab = .squad
                        selectedSquadSubTab = .players // Reset par défaut
                    }) {
                        Text(tab.rawValue.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(textColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Menu {
                        ForEach(ClubSquadSubTab.allCases) { sub in
                            Button(sub.rawValue) {
                                selectedTab = .squad
                                selectedSquadSubTab = sub
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(textColor)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .menuIndicator(.hidden)
                }
                
                // 3. Logique pour les onglets simples (Schedule, History)
                else {
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity) // Pour que la zone de clic soit large
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Indicateur jaune (ligne du bas)
            Rectangle()
                .fill(isSelected ? Color.yellow : Color.clear)
                .frame(height: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 15)
        .background(Color.white.opacity(0.02))
    }
    
    // MARK: - LOGIQUE DU CONTENU
    
    @ViewBuilder
    private var contentView: some View {
        if let club = club {
            switch selectedTab {
                
            // --- OVERVIEW ---
            case .overview:
                switch selectedOverviewSubTab {
                case .profile:
                    ClubProfileView(club: club)
                case .general:
                    ClubGeneralInfoView(club: club)
                }
                
            // --- SQUAD ---
            case .squad:
                switch selectedSquadSubTab {
                case .players:
                    ClubSquadListView(club: club)
                case .tactic:
                    ClubTacticView(club: club)
                }
                
            // --- SCHEDULE ---
            case .schedule:
                ClubScheduleView(clubId: club.id, seasonId: seasonId)
                
            // --- HISTORY ---
            case .history:
                ClubHistoryView(clubId: clubId)
            }
        } else {
            // Cas d'erreur si l'ID est mauvais
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                Text("Club not found").foregroundColor(.white)
            }
        }
    }
}

// MARK: - 3. SOUS-VUES (PLACEHOLDERS AVEC DESIGN)

// --- A. PROFILE ---
// Voir ClubProfileView.swift

// --- B. GENERAL ---
struct ClubGeneralInfoView: View {
    let club: Club
    var body: some View {
        VStack {
            Text("General Information").font(.title2).foregroundColor(.gray)
            Text("Finances, Board, Rivalries...").foregroundColor(.gray.opacity(0.5))
        }
    }
}

// --- C. SQUAD (PLAYERS) ---
struct ClubSquadListView: View {
    let club: Club
    // Simulation de récupération de joueurs (à remplacer par votre vraie logique)
    let players = ["Player 1", "Player 2", "Player 3"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // En-tête Tableau
                HStack {
                    Text("NAME").frame(maxWidth: .infinity, alignment: .leading)
                    Text("POS").frame(width: 50)
                    Text("AGE").frame(width: 40)
                    Text("NAT").frame(width: 40)
                }
                .font(.caption).bold().foregroundColor(.gray)
                .padding()
                .background(Color.white.opacity(0.05))
                
                // Liste
                ForEach(0..<15, id: \.self) { i in
                    HStack {
                        HStack {
                            Circle().fill(Color.gray).frame(width: 30, height: 30)
                            Text("Player Name \(i+1)").foregroundColor(.white).fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("MC").font(.caption).bold().foregroundColor(.white).frame(width: 50)
                        Text("24").foregroundColor(.gray).frame(width: 40)
                        Text("🇲🇦").frame(width: 40)
                    }
                    .padding()
                    .background(i % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)
                }
            }
        }
    }
}

// --- D. TACTIC ---
struct ClubTacticView: View {
    let club: Club
    var body: some View {
        VStack {
            Image(systemName: "checkerboard.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.green.opacity(0.5))
            Text("Tactical Board").font(.headline).foregroundColor(.white).padding()
            Text("Formation: 4-3-3").foregroundColor(.yellow)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


// Petit composant helper pour les cartes d'info
struct InfoCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 5) {
            Text(title).font(.caption).bold().foregroundColor(.gray)
            Text(value).font(.subheadline).bold().foregroundColor(.white).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}
