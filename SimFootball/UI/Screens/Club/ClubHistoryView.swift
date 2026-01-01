//
//  ClubHistoryView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 28/12/2025.
//

import SwiftUI

struct ClubHistoryView: View {
    let clubId: String
    
    // Récupérer l'historique depuis la BDD (Trié du plus récent au plus ancien)
    var history: [TeamSeasonHistory] {
        GameDatabase.shared.getHistory(forTeam: clubId)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. EN-TÊTE DU TABLEAU
            HStack(spacing: 0) {
                Text("YEAR").frame(width: 80, alignment: .leading)
                Text("LEAGUE").frame(width: 150, alignment: .leading)
                Text("POS").frame(width: 50, alignment: .center)
                Text("CUP").frame(width: 150, alignment: .leading)
                Text("CONTINENTAL").frame(width: 150, alignment: .leading)
                Spacer() // Espace flexible
            }
            .font(.system(size: 10, weight: .black))
            .foregroundColor(.gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            
            // 2. LISTE DES SAISONS
            ScrollView {
                LazyVStack(spacing: 0) {
                    if history.isEmpty {
                        EmptyHistoryView()
                    } else {
                        ForEach(Array(history.enumerated()), id: \.element.id) { index, season in
                            HistoryRow(season: season, isAlternate: index % 2 != 0)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color(hex: "121212"))
        .cornerRadius(12)
        .padding(16) // Padding externe
    }
}

// MARK: - LIGNE D'HISTORIQUE

struct HistoryRow: View {
    let season: TeamSeasonHistory
    let isAlternate: Bool
    
    // Helpers pour extraire les perfs spécifiques
    
    // 1. Championnat (Le premier trouvé qui n'est pas une coupe)
    var leaguePerf: CompetitionPerformance? {
        season.performances.first { perf in
            let comp = GameDatabase.shared.competitions.first(where: { $0.id == perf.competitionId })
            return comp?.type == .league
        }
    }
    
    // 2. Coupe Nationale (Le premier trouvé type coupe)
    var cupPerf: CompetitionPerformance? {
        season.performances.first { perf in
            let comp = GameDatabase.shared.competitions.first(where: { $0.id == perf.competitionId })
            return comp?.type == .cup
        }
    }
    
    // 3. Continental (Le premier trouvé type continental)
    var continentalPerf: CompetitionPerformance? {
        season.performances.first { perf in
            let comp = GameDatabase.shared.competitions.first(where: { $0.id == perf.competitionId })
            return comp?.type == .continental
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            
            // 1. ANNÉE
            Text(season.yearLabel)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            
            // 2. CHAMPIONNAT (Nom)
            if let perf = leaguePerf, let comp = GameDatabase.shared.competitions.first(where: { $0.id == perf.competitionId }) {
                HStack(spacing: 6) {
                    CompetitionLogoView(competitionId: comp.id, size: 16)
                    Text(comp.shortName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(width: 150, alignment: .leading)
                
                // 3. POSITION (Badge)
                Text(perf.rankLabel)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(getColor(forRank: perf.preciseRank ?? 10))
                    .frame(width: 50, alignment: .center)
                    .background(
                        perf.isWinner ? Color.yellow.opacity(0.2) : Color.clear
                    )
                    .cornerRadius(4)
                
            } else {
                Text("-").font(.caption).frame(width: 150, alignment: .leading)
                Text("-").font(.caption).frame(width: 50, alignment: .center)
            }
            
            // 4. COUPE
            if let perf = cupPerf {
                Text(perf.rankLabel) // Affiche "Winner", "Semi-Final", etc.
                    .font(.system(size: 11, weight: perf.isWinner ? .black : .regular))
                    .foregroundColor(perf.isWinner ? .yellow : .gray)
                    .frame(width: 150, alignment: .leading)
            } else {
                Text("-").font(.caption).foregroundColor(.gray.opacity(0.3)).frame(width: 150, alignment: .leading)
            }
            
            // 5. CONTINENTAL
            if let perf = continentalPerf {
                Text(perf.rankLabel)
                    .font(.system(size: 11, weight: perf.isWinner ? .black : .regular))
                    .foregroundColor(perf.isWinner ? .yellow : .blue)
                    .frame(width: 150, alignment: .leading)
            } else {
                Text("-").font(.caption).foregroundColor(.gray.opacity(0.3)).frame(width: 150, alignment: .leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isAlternate ? Color.white.opacity(0.03) : Color.clear)
    }
    
    // Couleur dynamique pour le classement
    func getColor(forRank rank: Int) -> Color {
        switch rank {
        case 1: return .yellow      // Champion
        case 2...4: return .green   // Europe/Afrique
        case 14...20: return .red   // Relégation (à adapter)
        default: return .white
        }
    }
}

// Vue vide
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.3))
            Text("No history recorded yet.")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Complete a season to see results here.")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }
}
