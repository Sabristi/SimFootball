//
//  LeagueDetailsView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 30/11/2025.
//

import SwiftUI

enum LeagueSubTab: String, CaseIterable {
    case overview = "Overview"
    case ranking = "Ranking"
    case fixtures = "Fixtures"
    case stats = "Stats"
    case history = "History"
}

struct LeagueDetailsView: View {
    let competitionId: String
    let seasonId: String
    
    @State private var selectedSubTab: LeagueSubTab = .overview
    
    // Récupération des données
    var competitionSeason: CompetitionSeason? {
        GameDatabase.shared.getCompetitionSeason(competitionId: competitionId, seasonId: seasonId)
    }
    
    var competitionInfo: Competition? {
        GameDatabase.shared.competitions.first { $0.id == competitionId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. HEADER DE LA LIGUE
            HStack(spacing: 20) {
                // Logo Compétition (Placeholder ou ShortName)
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(competitionInfo?.shortName.prefix(1) ?? "L")
                            .font(.largeTitle).bold().foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(competitionInfo?.name.uppercased() ?? "UNKNOWN LEAGUE")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Season \(competitionSeason?.yearLabel ?? "Unknown")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color.black.opacity(0.4))
            
            // 2. BARRE D'ONGLETS INTERNE
            HStack(spacing: 0) {
                ForEach(LeagueSubTab.allCases, id: \.self) { tab in
                    Button(action: { selectedSubTab = tab }) {
                        VStack(spacing: 8) {
                            Text(tab.rawValue.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(selectedSubTab == tab ? .yellow : .gray)
                            
                            // Barre indicatrice
                            Rectangle()
                                .fill(selectedSubTab == tab ? Color.yellow : Color.clear)
                                .frame(height: 3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 15)
                        .background(Color.white.opacity(0.02))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color.black.opacity(0.6))
            
            // 3. CONTENU VARIABLE
            ZStack {
                Color.clear // Fond
                
                if let season = competitionSeason {
                    // Vérification du statut
                    if season.status == .planned /* ou "Not Scheduled" si string */ {
                        VStack(spacing: 15) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("Competition Not Scheduled Yet")
                                .font(.title3).bold()
                                .foregroundColor(.white)
                            Text("The draw for the upcoming season has not taken place.")
                                .foregroundColor(.gray)
                        }
                    } else {
                        // Affichage normal selon l'onglet
                        switch selectedSubTab {
                        case .overview:
                            LeagueOverviewView(competitionId: competitionId, seasonId: seasonId)
                        case .ranking:
                            // On réutilise notre composant DataTable si possible, sinon une vue dédiée
                            LeagueRankingView(competitionId: competitionId, seasonId: seasonId)
                        case .fixtures:
                            Text("Fixtures Calendar Placeholder").foregroundColor(.gray)
                        case .stats:
                            Text("Player Stats Placeholder").foregroundColor(.gray)
                        case .history:
                            Text("History Placeholder").foregroundColor(.gray)
                        }
                    }
                } else {
                    Text("Season Data Not Found").foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: "121212")) // Fond général de la page
    }
}

// --- SOUS-VUE : OVERVIEW (Classement sommaire + Prochains Matchs) ---
struct LeagueOverviewView: View {
    let competitionId: String
    let seasonId: String
    
    var nextMatchDay: MatchDay? {
        // Trouve la première journée non jouée
        GameDatabase.shared.matchDays
            .filter { $0.competitionId == competitionId && $0.seasonId == seasonId && !$0.isPlayed }
            .sorted { $0.date < $1.date }
            .first
    }
    
    var matches: [Match] {
        guard let md = nextMatchDay else { return [] }
        // Récupère les matchs de cette journée
        return GameDatabase.shared.matches.filter { $0.matchDayId == md.id }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // COLONNE GAUCHE : CLASSEMENT (Top 5 + Bot 3 par exemple)
            VStack(alignment: .leading) {
                Text("LEAGUE TABLE").font(.headline).foregroundColor(.gray).padding(.bottom, 10)
                LeagueRankingView(competitionId: competitionId, seasonId: seasonId, isCompact: true)
            }
            .frame(maxWidth: .infinity)
            
            // COLONNE DROITE : PROCHAINE JOURNÉE
            VStack(alignment: .leading) {
                HStack {
                    Text("NEXT FIXTURES")
                    Spacer()
                    if let md = nextMatchDay {
                        Text(md.label).foregroundColor(.yellow)
                    }
                }
                .font(.headline).foregroundColor(.gray).padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 8) {
                        if matches.isEmpty {
                            Text("No upcoming matches scheduled").foregroundColor(.gray).italic()
                        } else {
                            ForEach(matches) { match in
                                MatchRowView(match: match)
                            }
                        }
                    }
                }
            }
            .frame(width: 350) // Largeur fixe pour la colonne matchs
        }
        .padding()
    }
}

// --- COMPOSANT LIGNE DE MATCH SIMPLIFIÉE ---
struct MatchRowView: View {
    let match: Match
    
    var homeName: String {
        match.homeTeamId != nil ? (GameDatabase.shared.getClub(byId: match.homeTeamId!)?.name ?? match.homeTeamAlias) : match.homeTeamAlias
    }
    
    var awayName: String {
        match.awayTeamId != nil ? (GameDatabase.shared.getClub(byId: match.awayTeamId!)?.name ?? match.awayTeamAlias) : match.awayTeamAlias
    }
    
    var body: some View {
        HStack {
            Text(homeName)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text("vs")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 5)
            
            Text(awayName)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let time = match.kickoffTime {
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .padding(4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .foregroundColor(.white)
    }
}

// --- SOUS-VUE : CLASSEMENT ---
struct LeagueRankingView: View {
    let competitionId: String
    let seasonId: String
    var isCompact: Bool = false
    
    var table: [LeagueTableEntry] {
        let fullTable = GameDatabase.shared.getLeagueTable(competitionId: competitionId, seasonId: seasonId)
        if isCompact {
            return Array(fullTable.prefix(8)) // Affiche juste les 8 premiers pour l'overview
        }
        return fullTable
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Tableau
            HStack {
                Text("POS").frame(width: 30)
                Text("CLUB").frame(maxWidth: .infinity, alignment: .leading)
                Text("PL").frame(width: 30)
                Text("GD").frame(width: 30)
                Text("PTS").frame(width: 30).foregroundColor(.white)
            }
            .font(.caption).bold().foregroundColor(.gray)
            .padding(.bottom, 8)
            .padding(.horizontal, 8)
            
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(table.indices, id: \.self) { index in
                        let entry = table[index]
                        let clubName = GameDatabase.shared.getClub(byId: entry.teamId)?.name ?? entry.teamAlias
                        
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption).bold()
                                .frame(width: 30)
                                .foregroundColor(index < 3 ? .green : .white) // Couleur pour le top 3
                            
                            Text(clubName)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(entry.played)").frame(width: 30).foregroundColor(.gray)
                            Text("\(entry.goalDifference)").frame(width: 30).foregroundColor(.gray)
                            Text("\(entry.points)").bold().frame(width: 30).foregroundColor(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(Color.white.opacity(index % 2 == 0 ? 0.05 : 0.02))
                        .cornerRadius(4)
                    }
                }
            }
        }
    }
}
