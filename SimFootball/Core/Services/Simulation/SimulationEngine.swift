//
//  SimulationEngine.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 03/12/2025.
//

import Foundation

class SimulationEngine {
    static let shared = SimulationEngine()
    
    private init() {}
    
    // MARK: - MOTEUR PRINCIPAL
    
    /// Simule une liste de matchs et met à jour la base de données (Scores, Statuts, Classements)
    /// Retourne la liste des matchs mis à jour
    func simulateMatches(_ matches: [Match]) -> [Match] {
        var updatedMatches: [Match] = []
        
        print("⚙️ [SimulationEngine] Début de la simulation pour \(matches.count) matchs...")
        
        for match in matches {
            // 1. Simulation du temps réglementaire (90 min)
            // TODO: Améliorer avec les notes des équipes (Attaque vs Défense)
            var homeGoals = Int.random(in: 0...3)
            var awayGoals = Int.random(in: 0...2)
            
            // Bonus Domicile léger
            if match.isPlayingHome && Int.random(in: 0...10) > 7 { homeGoals += 1 }
            
            // 2. Gestion des Prolongations / Tirs au but selon le type de match
            var homePenalties: Int? = nil
            var awayPenalties: Int? = nil
            var wasExtraTime = false
            
            // A. COUPE (Match Sec)
            if match.type == .knockoutSingle {
                if homeGoals == awayGoals {
                    // Égalité -> Prolongations
                    wasExtraTime = true
                    // Simulation simple de la prolongation (0 ou 1 but de plus)
                    if Bool.random() { homeGoals += 1 }
                    if Bool.random() { awayGoals += 1 }
                    
                    // Si toujours égalité -> Tirs au but
                    if homeGoals == awayGoals {
                        homePenalties = Int.random(in: 3...5)
                        awayPenalties = Int.random(in: 2...5)
                        // On s'assure qu'il y a un vainqueur aux TAB
                        while homePenalties == awayPenalties {
                            homePenalties! += 1
                        }
                    }
                }
            }
            
            // B. MATCH RETOUR (Second Leg)
            else if match.type == .secondLeg, let firstLegId = match.firstLegMatchId {
                            // Récupération du match aller
                            if let firstLeg = GameDatabase.shared.matches.first(where: { $0.id == firstLegId }) {
                                
                                // On détermine combien de buts l'équipe DOMICILE ACTUELLE a marqués à l'aller
                                let goalsScoredByHomeInLeg1: Int
                                if firstLeg.homeTeamId == match.homeTeamId {
                                    goalsScoredByHomeInLeg1 = firstLeg.homeTeamGoals ?? 0
                                } else {
                                    goalsScoredByHomeInLeg1 = firstLeg.awayTeamGoals ?? 0
                                }
                                
                                // On détermine combien de buts l'équipe EXTÉRIEUR ACTUELLE a marqués à l'aller
                                let goalsScoredByAwayInLeg1: Int
                                if firstLeg.homeTeamId == match.awayTeamId {
                                    goalsScoredByAwayInLeg1 = firstLeg.homeTeamGoals ?? 0
                                } else {
                                    goalsScoredByAwayInLeg1 = firstLeg.awayTeamGoals ?? 0
                                }
                                
                                // Calcul Aggregat
                                let totalAggHome = homeGoals + goalsScoredByHomeInLeg1
                                let totalAggAway = awayGoals + goalsScoredByAwayInLeg1
                                
                                if totalAggHome == totalAggAway {
                                    // Égalité parfaite sur les deux matchs -> Prolongations
                                    wasExtraTime = true
                                    
                                    // Simulation prolongation
                                    if Bool.random() { homeGoals += 1 }
                                    if Bool.random() { awayGoals += 1 }
                                    
                                    // Recalcul après prolongations pour voir si TAB
                                    let finalAggHome = homeGoals + goalsScoredByHomeInLeg1
                                    let finalAggAway = awayGoals + goalsScoredByAwayInLeg1
                                    
                                    if finalAggHome == finalAggAway {
                                        homePenalties = Int.random(in: 3...5)
                                        awayPenalties = Int.random(in: 2...5)
                                        while homePenalties == awayPenalties { homePenalties! += 1 }
                                    }
                                }
                            }
            }
            
            // 3. Mise à jour de l'objet Match
            var updatedMatch = match
            updatedMatch.homeTeamGoals = homeGoals
            updatedMatch.awayTeamGoals = awayGoals
            updatedMatch.homePenalties = homePenalties
            updatedMatch.awayPenalties = awayPenalties
            updatedMatch.wasExtraTimePlayed = wasExtraTime
            updatedMatch.status = .played
            
            // 4. Sauvegarde dans la DB
            if let index = GameDatabase.shared.matches.firstIndex(where: { $0.id == match.id }) {
                GameDatabase.shared.matches[index] = updatedMatch
            }
            updatedMatches.append(updatedMatch)
            
            // 5. Mise à jour du CLASSEMENT (Uniquement pour les championnats)
            if match.type == .league, let tableId = match.tableId {
                updateLeagueTable(match: updatedMatch, tableId: tableId)
            }
        }
        
        // 6. Gestion de fin de Journée (MatchDay)
        let dayIds = Set(matches.map { $0.matchDayId })
        for dayId in dayIds {
            checkAndCloseMatchDay(dayId: dayId)
        }
        
        print("✅ [SimulationEngine] Simulation terminée.")
        return updatedMatches
    }
    
    // MARK: - LOGIQUE CLASSEMENT (LIGUE)
    
    private func updateLeagueTable(match: Match, tableId: String) {
        guard let hGoals = match.homeTeamGoals, let aGoals = match.awayTeamGoals,
              let hTeamId = match.homeTeamId, let aTeamId = match.awayTeamId else { return }
        
        // Mise à jour Domicile
        updateTeamEntry(teamId: hTeamId, scored: hGoals, conceded: aGoals, tableId: tableId)
        
        // Mise à jour Extérieur
        updateTeamEntry(teamId: aTeamId, scored: aGoals, conceded: hGoals, tableId: tableId)
    }
    
    private func updateTeamEntry(teamId: String, scored: Int, conceded: Int, tableId: String) {
        // On cherche l'entrée correspondante dans la DB
        guard let index = GameDatabase.shared.leagueTables.firstIndex(where: { $0.teamId == teamId && $0.tableId == tableId }) else {
            // C'est normal si c'est une coupe, il n'y a pas de classement
            return
        }
        
        var entry = GameDatabase.shared.leagueTables[index]
        
        // Stats
        entry.played += 1
        entry.goalsFor += scored
        entry.goalsAgainst += conceded
        
        // Points & Résultat
        let resultChar: String
        if scored > conceded {
            entry.points += 3
            entry.won += 1
            resultChar = "W"
        } else if scored == conceded {
            entry.points += 1
            entry.drawn += 1
            resultChar = "D"
        } else {
            entry.lost += 1
            resultChar = "L"
        }
        
        // Forme (5 derniers matchs)
        entry.form.append(resultChar)
        if entry.form.count > 5 { entry.form.removeFirst() }
        
        // Sauvegarde
        GameDatabase.shared.leagueTables[index] = entry
    }
    
    // MARK: - LOGIQUE FIN DE JOURNÉE
    
    private func checkAndCloseMatchDay(dayId: String) {
        // On vérifie si TOUS les matchs de cette journée sont joués
        let allMatches = GameDatabase.shared.matches.filter { $0.matchDayId == dayId }
        let allPlayed = allMatches.allSatisfy { $0.status == .played }
        
        if allPlayed {
            if let index = GameDatabase.shared.matchDays.firstIndex(where: { $0.id == dayId }) {
                GameDatabase.shared.matchDays[index].isPlayed = true
                print("🏁 Journée \(dayId) clôturée (isPlayed = true)")
                
                // Si c'est un championnat, on met à jour les positions (1er, 2ème...)
                let competitionId = GameDatabase.shared.matchDays[index].competitionId
                if let competition = GameDatabase.shared.competitions.first(where: { $0.id == competitionId }), competition.type == .league {
                    recalculatePositions(competitionId: competitionId)
                }
            }
        }
    }
    
    private func recalculatePositions(competitionId: String) {
        // On récupère toutes les entrées de ce championnat
        var entries = GameDatabase.shared.leagueTables.filter { $0.competitionId == competitionId }
        
        // Tri selon les règles standard (Points > Diff > Buts Pour)
        entries.sort {
            if $0.points != $1.points { return $0.points > $1.points }
            if $0.goalDifference != $1.goalDifference { return $0.goalDifference > $1.goalDifference }
            return $0.goalsFor > $1.goalsFor
        }
        
        // Application des rangs
        for (rank, entry) in entries.enumerated() {
            if let dbIndex = GameDatabase.shared.leagueTables.firstIndex(where: { $0.id == entry.id }) {
                GameDatabase.shared.leagueTables[dbIndex].position = rank + 1
            }
        }
    }
}
