//
//  KnockOutCompetitionView.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import SwiftUI

// Onglets spécifiques aux Coupes
enum CupSubTab: String, CaseIterable {
    case overview = "Overview"
    case bracket = "Bracket" // 🏆 Remplace le Ranking
    case fixtures = "Fixtures"
    case stats = "Stats"
    case history = "History"
}

struct KnockOutCompetitionView: View {
    let competitionId: String
    let seasonId: String
    
    @State private var selectedSubTab: CupSubTab = .overview
    @State private var selectedOverviewSubTab: OverviewSubTab = .profile
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. BARRE D'ONGLETS (Adaptée Coupe)
            HStack(spacing: 0) {
                ForEach(CupSubTab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .background(Color.black.opacity(0.6))
            
            // 2. CONTENU
            ZStack {
                Color.clear
                switch selectedSubTab {
                case .overview:
                    switch selectedOverviewSubTab {
                    case .profile:
                        // ✅ Vue Overview Spéciale Coupe
                        CupOverviewView(competitionId: competitionId, seasonId: seasonId)
                    default:
                        Text("\(selectedOverviewSubTab.rawValue) Placeholder").foregroundColor(.gray)
                    }
                    
                case .bracket:
                    // TODO: Implémenter la vue de l'arbre du tournoi
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.indent").font(.system(size: 50)).foregroundColor(.gray)
                        Text("Tournament Bracket").font(.title2).bold().foregroundColor(.white)
                        Text("Visualisation des tours à venir...").foregroundColor(.gray)
                    }
                    
                case .fixtures:
                    // On réutilise la vue existante qui marche très bien pour lister les matchs
                    LeagueFixturesView(competitionId: competitionId, seasonId: seasonId)
                    
                case .stats:
                    Text("Player Stats Placeholder").foregroundColor(.gray)
                    
                case .history:
                    CompetitionHistoryView(competitionId: competitionId)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: "121212"))
    }
    
    // Boutons d'onglets (Code similaire à LeagueDetailsView mais typé CupSubTab)
    @ViewBuilder
    private func tabButton(for tab: CupSubTab) -> some View {
        if tab == .overview {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Button(action: { selectedSubTab = .overview; selectedOverviewSubTab = .profile }) {
                        Text("OVERVIEW").font(.system(size: 12, weight: .bold))
                            .foregroundColor(selectedSubTab == tab ? .yellow : .gray)
                    }.buttonStyle(PlainButtonStyle())
                    
                    Menu {
                        ForEach(OverviewSubTab.allCases) { sub in
                            Button(sub.rawValue) { selectedSubTab = .overview; selectedOverviewSubTab = sub }
                        }
                    } label: {
                        Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                            .foregroundColor(selectedSubTab == tab ? .yellow : .gray)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .menuIndicator(.hidden)
                }
                Rectangle().fill(selectedSubTab == tab ? Color.yellow : Color.clear).frame(height: 3)
            }
            .frame(maxWidth: .infinity).padding(.top, 15).background(Color.white.opacity(0.02))
        } else {
            Button(action: { selectedSubTab = tab }) {
                VStack(spacing: 8) {
                    Text(tab.rawValue.uppercased()).font(.system(size: 12, weight: .bold))
                        .foregroundColor(selectedSubTab == tab ? .yellow : .gray)
                    Rectangle().fill(selectedSubTab == tab ? Color.yellow : Color.clear).frame(height: 3)
                }
                .frame(maxWidth: .infinity).padding(.top, 15).background(Color.white.opacity(0.02))
            }.buttonStyle(PlainButtonStyle())
        }
    }
}


struct CupOverviewView: View {
    let competitionId: String
    let seasonId: String
    
    var competition: Competition? {
        GameDatabase.shared.competitions.first(where: { $0.id == competitionId })
    }
    
    // Récupérer le prochain match à jouer dans cette coupe
    var nextMatchDay: MatchDay? {
        GameDatabase.shared.matchDays
            .filter { $0.competitionId == competitionId && $0.seasonId == seasonId && !$0.isPlayed }
            .sorted { $0.date < $1.date }
            .first
    }
    
    var matches: [Match] {
        guard let md = nextMatchDay else { return [] }
        return GameDatabase.shared.matches.filter { $0.matchDayId == md.id }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // GAUCHE : Infos Clés (Tenant du titre mis en avant)
            VStack(alignment: .leading, spacing: 15) {
                if let comp = competition {
                    // Bloc Tenant du Titre plus imposant pour la coupe
                    VStack(alignment: .leading, spacing: 10) {
                        Text("REIGNING CHAMPION").font(.caption).fontWeight(.black).foregroundColor(.gray).tracking(1)
                        
                        if let winnerId = comp.titleHolderId, let club = GameDatabase.shared.getClub(byId: winnerId) {
                            HStack(spacing: 15) {
                                ClubLogoView(clubId: club.id, size: 60)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(club.name.uppercased())
                                        .font(.title3).fontWeight(.heavy).foregroundColor(.white)
                                    Text("Botola Pro 1") // Exemple de sous-titre dynamique à ajouter
                                        .font(.caption).foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                        } else {
                            Text("No current champion").foregroundColor(.gray).italic()
                        }
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
            
            // DROITE : Calendrier et Diffuseurs
            VStack(alignment: .leading, spacing: 15) {
                if let comp = competition {
                    LeagueBroadcastersView(competition: comp)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("UPCOMING ROUND").font(.system(size: 9, weight: .medium)).foregroundColor(.gray).tracking(0.5)
                        Spacer()
                        if let md = nextMatchDay {
                            Text(md.label.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }.padding(.bottom, 10)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            if matches.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.title2).foregroundColor(.gray)
                                    Text("No matches scheduled")
                                        .font(.caption).foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 30)
                            } else {
                                ForEach(matches) { match in
                                    // isCompact: true pour une version ligne simple
                                    MatchRowView(match: match, useAcronym: true, isCompact: true)
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: 450)
        }
        .padding()
    }
}
