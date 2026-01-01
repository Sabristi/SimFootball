//
//  MatchDayView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 03/12/2025.
//

import SwiftUI

struct MatchDayView: View {
    let date: Date
    
    // Callback pour la navigation vers la ligue
    var onCompetitionTap: ((String) -> Void)?
    
    // --- DONNÉES ---
    var todaysMatches: [Match] {
        return GameDatabase.shared.getMatches(forDate: date)
    }
    
    var groupedMatches: [String: [Match]] {
        Dictionary(grouping: todaysMatches, by: { $0.competitionId })
    }
    
    var activeCompetitions: [Competition] {
        groupedMatches.keys.compactMap { compId in
            GameDatabase.shared.competitions.first(where: { $0.id == compId })
        }.sorted { $0.shortName < $1.shortName }
    }
    
    // --- HELPER : Trouver le nom de la journée (ex: "Journée 8") ---
    func getMatchDayName(for competitionId: String) -> String {
        // 1. On prend un match au hasard de cette compétition pour ce jour
        guard let matches = groupedMatches[competitionId], let firstMatch = matches.first else { return "" }
        
        // 2. On récupère l'objet MatchDay via l'ID stocké dans le match
        if let matchDay = GameDatabase.shared.matchDays.first(where: { $0.id == firstMatch.matchDayId }) {
            return matchDay.name // Renvoie "Journée 1", "Journée 2"...
        }
        return ""
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                
                if activeCompetitions.isEmpty {
                    VStack(spacing: 15) {
                        Spacer()
                        Image(systemName: "sportscourt").font(.largeTitle).foregroundColor(.gray.opacity(0.3))
                        Text("No matches scheduled for this day.")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .frame(height: 300)
                } else {
                    ForEach(activeCompetitions) { competition in
                        VStack(alignment: .leading, spacing: 0) {
                            
                            // A. EN-TÊTE DE LA COMPÉTITION (CLIQUABLE)
                            Button(action: {
                                onCompetitionTap?(competition.id)
                            }) {
                                HStack(spacing: 8) {
                                    CompetitionLogoView(competitionId: competition.id, size: 24)
                                    
                                    // Nom de la Compétition
                                    Text(competition.name.uppercased())
                                        .font(.caption)
                                        .fontWeight(.black)
                                        .foregroundColor(.white)
                                    
                                    // SÉPARATEUR
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    // NOM DE LA JOURNÉE
                                    Text(getMatchDayName(for: competition.id).uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.yellow) // Mis en valeur en jaune
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.02))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // B. LISTE DES MATCHS GROUPÉS PAR HEURE
                            if let matches = groupedMatches[competition.id] {
                                
                                // 1. Grouper par heure de coup d'envoi
                                let matchesByTime = Dictionary(grouping: matches) { match in
                                    match.kickoffTime ?? Date.distantFuture
                                }
                                
                                // 2. Trier les heures (clés)
                                let sortedTimes = matchesByTime.keys.sorted()
                                
                                // 3. Boucle sur les créneaux horaires
                                ForEach(sortedTimes, id: \.self) { time in
                                    VStack(spacing: 0) {
                                        
                                        // En-tête Horaire (14:00, 20:00...)
                                        HStack {
                                            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                                            Text(time.formatted(date: .omitted, time: .shortened))
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.gray)
                                                .padding(.horizontal, 4)
                                                .background(Color.black) // Cache la ligne derrière le texte
                                            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal)
                                        
                                        // Liste des matchs pour ce créneau
                                        if let timeMatches = matchesByTime[time] {
                                            // Tri par ID pour garder un ordre stable
                                            let sortedTimeMatches = timeMatches.sorted { $0.id < $1.id }
                                            
                                            ForEach(sortedTimeMatches) { match in
                                                // ✅ Appel simplifié : MatchRowView gère l'affichage (Position/Division) via la DB
                                                MatchRowView(
                                                    match: match,
                                                    useAcronym: false,
                                                    isCompact: false
                                                )
                                                .padding(.horizontal)
                                                .padding(.bottom, 4)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 15)
                    }
                }
                
                Color.clear.frame(height: 50)
            }
            .padding(.top, 20)
        }
    }
}
