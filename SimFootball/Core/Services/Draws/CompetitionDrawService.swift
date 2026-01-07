//
//  CompetitionDrawService.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import Foundation

class CompetitionDrawService {
    
    static let shared = CompetitionDrawService()
    private let db = GameDatabase.shared
    
    private init() {}
    
    // MARK: - 1. POINT D'ENTRÉE PRINCIPAL (AUTOMATISATION)
    
    /// Lance le tirage approprié selon le type de compétition (Ligue ou Coupe)
    func performDrawForCurrentStage(competitionId: String, seasonId: String, roundId: String? = nil) {
        print("🎲 [DrawService] Lancement du tirage pour \(competitionId) (Saison \(seasonId))...")
        
        guard let competition = db.competitions.first(where: { $0.id == competitionId }) else {
            print("❌ Compétition introuvable : \(competitionId)")
            return
        }
        
        // AIGUILLAGE SELON LE TYPE
        if competition.type == .league {
            let success = performDrawForLeague(competitionId: competitionId, seasonId: seasonId)
            if success { print("✅ Tirage Ligue terminé avec succès.") }
            else { print("❌ Échec du tirage Ligue.") }
            
        } else if competition.type == .cup {
            // ✅ GESTION COUPE
            guard let rId = roundId else {
                print("⚠️ Impossible de tirer la Coupe : roundId manquant.")
                return
            }
            
            let success = performDrawForCup(competitionId: competitionId, seasonId: seasonId, roundId: rId)
            if success { print("✅ Tirage Coupe (\(rId)) terminé avec succès.") }
            else { print("❌ Échec du tirage Coupe (\(rId)).") }
        }
    }
    
    // MARK: - 2. LOGIQUE TIRAGE LIGUE (Recyclage)
    
    func performDrawForLeague(competitionId: String, seasonId: String) -> Bool {
        print("🎲 [DrawService] Recyclage du tirage pour \(competitionId) - Saison \(seasonId)")
        
        // 1. Récupérer la saison CIBLE
        guard let compSeason = db.getCompetitionSeason(competitionId: competitionId, seasonId: seasonId) else {
            print("❌ Compétition Season introuvable pour \(seasonId)")
            return false
        }
        
        // 2. Récupérer les MatchDays
        let matchDays = db.matchDays
            .filter { $0.competitionId == competitionId && $0.seasonId == seasonId }
            .sorted { $0.index < $1.index }
        
        guard !matchDays.isEmpty else {
            print("❌ Erreur : Pas de journées (MatchDays) trouvées pour recycler.")
            return false
        }
        
        // 3. Générer les paires (Algorithme de Berger)
        let teamIds = compSeason.teamIds
        let fixtures = generateBergerTable(teams: teamIds)
        
        var updatedCount = 0
        let shortCode = competitionId.components(separatedBy: "-").last ?? "LGE"
        let tableId = "\(shortCode)-REG"
        
        // 4. BOUCLE DE RECYCLAGE
        for (dayIndex, dayFixtures) in fixtures.enumerated() {
            if dayIndex < matchDays.count {
                let currentDay = matchDays[dayIndex]
                
                let matchIndices = db.matches.indices
                    .filter { db.matches[$0].matchDayId == currentDay.id }
                    .sorted { db.matches[$0].id < db.matches[$1].id }
                
                for (matchIndex, pair) in dayFixtures.enumerated() {
                    if matchIndex < matchIndices.count {
                        let dbIndex = matchIndices[matchIndex]
                        let (homeId, awayId) = pair
                        
                        var match = db.matches[dbIndex]
                        
                        match.homeTeamId = homeId
                        match.awayTeamId = awayId
                        match.stadiumId = db.getClub(byId: homeId)?.stadiumId
                        match.kickoffTime = currentDay.date
                        match.status = .scheduled
                        
                        // Reset des scores
                        match.homeTeamGoals = nil
                        match.awayTeamGoals = nil
                        match.homePenalties = nil
                        match.awayPenalties = nil
                        
                        db.matches[dbIndex] = match
                        updatedCount += 1
                    }
                }
            }
        }
        
        print("   ♻️ \(updatedCount) matchs recyclés et mis à jour.")
        
        // 5. INITIALISER LE CLASSEMENT
        initializeLeagueTable(
            competitionId: competitionId,
            seasonId: seasonId,
            teamIds: teamIds,
            tableId: tableId,
            compSeasonId: compSeason.id,
            stageId: compSeason.currentStageId
        )
        
        // 6. METTRE À JOUR LE STATUT
        updateStatusToPlanned(compSeason: compSeason)
        
        return true
    }
    
    // MARK: - 3. LOGIQUE TIRAGE COUPE (CORRIGÉE & AUTOMATISÉE)
    
    func performDrawForCup(competitionId: String, seasonId: String, roundId: String) -> Bool {
        print("🏆 [DrawService] Tirage Coupe : \(roundId)")
        
        // 1. Récupérer les équipes qualifiées
        let qualifiedTeamIds = getQualifiedTeamsForCup(roundId: roundId)
        
        guard !qualifiedTeamIds.isEmpty else {
            print("❌ Aucune équipe qualifiée trouvée pour \(roundId).")
            return false
        }
        
        // 2. Effectuer le tirage (Mélange aléatoire)
        let shuffledTeams = qualifiedTeamIds.shuffled()
        var matches: [Match] = []
        
        // 3. Identification du Type de Tour (Aller/Retour ou Match Sec ?)
        // QF et SF sont Aller/Retour. R32, R16, FINAL sont Match Sec.
        let isTwoLegged = (roundId.contains("QF") || roundId.contains("SF")) && !roundId.contains("FINAL")
        
        // 4. Créer les matchs
        for i in stride(from: 0, to: shuffledTeams.count - 1, by: 2) {
            // Sécurité pour éviter index out of bounds si nombre impair (ne devrait pas arriver)
            if i+1 >= shuffledTeams.count { break }
            
            let teamA = shuffledTeams[i]
            let teamB = shuffledTeams[i+1]
            
            let clubA = db.getClub(byId: teamA)
            let clubB = db.getClub(byId: teamB)
            
            if isTwoLegged {
                // --- CAS ALLER / RETOUR (QF, SF) ---
                
                // MATCH 1 : ALLER (Chez A)
                let matchDay1Id = getMatchDayIdForRound(roundId, leg: 1)
                let date1 = db.matchDays.first(where: { $0.id == matchDay1Id })?.date
                let id1 = UUID().uuidString
                
                let match1 = Match(
                    id: id1,
                    competitionId: competitionId,
                    matchDayId: matchDay1Id,
                    homeTeamAlias: clubA?.shortName ?? "Team A",
                    awayTeamAlias: clubB?.shortName ?? "Team B",
                    homeTeamId: teamA,
                    awayTeamId: teamB,
                    stadiumId: clubA?.stadiumId,
                    kickoffTime: date1,
                    status: .scheduled,
                    type: .firstLeg // 🚨 Type Aller
                )
                
                // MATCH 2 : RETOUR (Chez B)
                let matchDay2Id = getMatchDayIdForRound(roundId, leg: 2)
                let date2 = db.matchDays.first(where: { $0.id == matchDay2Id })?.date
                
                let match2 = Match(
                    id: UUID().uuidString,
                    competitionId: competitionId,
                    matchDayId: matchDay2Id,
                    homeTeamAlias: clubB?.shortName ?? "Team B",
                    awayTeamAlias: clubA?.shortName ?? "Team A",
                    homeTeamId: teamB,
                    awayTeamId: teamA,
                    stadiumId: clubB?.stadiumId,
                    kickoffTime: date2,
                    status: .scheduled,
                    type: .secondLeg, // 🚨 Type Retour
                    firstLegMatchId: id1 // 🔗 LIEN CRUCIAL POUR L'AGRÉGAT
                )
                
                matches.append(match1)
                matches.append(match2)
                
            } else {
                // --- CAS MATCH SEC (R32, R16, FINAL) ---
                
                let matchDayId = getMatchDayIdForRound(roundId, leg: nil)
                let date = db.matchDays.first(where: { $0.id == matchDayId })?.date
                
                let match = Match(
                    id: UUID().uuidString,
                    competitionId: competitionId,
                    matchDayId: matchDayId,
                    homeTeamAlias: clubA?.shortName ?? "Team A",
                    awayTeamAlias: clubB?.shortName ?? "Team B",
                    homeTeamId: teamA,
                    awayTeamId: teamB,
                    stadiumId: clubA?.stadiumId, // Joue chez le premier tiré (pour la finale, on pourrait forcer un stade neutre)
                    kickoffTime: date,
                    status: .scheduled,
                    type: .knockoutSingle // 🚨 Type Match Sec
                )
                
                matches.append(match)
            }
        }
        
        // 5. Sauvegarder
        saveCupFixtures(matches: matches, roundId: roundId)
        
        // 6. METTRE À JOUR LE STATUT
        if let compSeason = db.getCompetitionSeason(competitionId: competitionId, seasonId: seasonId) {
            updateStatusToPlanned(compSeason: compSeason)
        }
        
        return true
    }
    
    // MARK: - HELPERS PRIVES
    
    private func updateStatusToPlanned(compSeason: CompetitionSeason) {
        if let index = db.competitionSeasons.firstIndex(where: { $0.id == compSeason.id }) {
            var updated = db.competitionSeasons[index]
            updated.status = .planned
            db.competitionSeasons[index] = updated
            
            db.saveCompetitionSeasons()
            db.saveMatches()
            print("   ✅ Statut mis à jour : PLANNED")
        }
    }
    
    // Algorithme de Berger (Round-Robin)
    private func generateBergerTable(teams: [String]) -> [[(String, String)]] {
        var rounds: [[(String, String)]] = []
        var teamList = teams
        if teamList.count % 2 != 0 { teamList.append("BYE") }
        let numTeams = teamList.count
        let numDays = numTeams - 1
        let halfSize = numTeams / 2
        
        for day in 0..<numDays {
            var roundMatches: [(String, String)] = []
            for i in 0..<halfSize {
                let t1 = teamList[i]
                let t2 = teamList[numTeams - 1 - i]
                if t1 != "BYE" && t2 != "BYE" {
                    if i == 0 { roundMatches.append(day % 2 == 0 ? (t1, t2) : (t2, t1)) }
                    else { roundMatches.append(day % 2 == 0 ? (t2, t1) : (t1, t2)) }
                }
            }
            rounds.append(roundMatches)
            let last = teamList.removeLast()
            teamList.insert(last, at: 1)
        }
        
        var returnRounds: [[(String, String)]] = []
        for round in rounds {
            var returnRound: [(String, String)] = []
            for match in round { returnRound.append((match.1, match.0)) }
            returnRounds.append(returnRound)
        }
        
        return rounds + returnRounds
    }
    
    // MARK: - INITIALISATION DU CLASSEMENT
    
    private func initializeLeagueTable(competitionId: String, seasonId: String, teamIds: [String], tableId: String, compSeasonId: String, stageId: String) {
        
        var updatedCount = 0
        let suffix = competitionId.components(separatedBy: "-").last ?? "BP1"
        
        for (index, newTeamId) in teamIds.enumerated() {
            let slotNumber = index + 1
            let targetAlias = "T\(slotNumber)_\(suffix)"
            
            if let dbIndex = db.leagueTables.firstIndex(where: {
                $0.competitionId == competitionId &&
                $0.stageId == stageId &&
                $0.teamAlias == targetAlias
            }) {
                var entry = db.leagueTables[dbIndex]
                
                entry.seasonId = seasonId
                entry.competitionSeasonId = compSeasonId
                entry.tableId = tableId
                entry.teamId = newTeamId
                
                // Reset stats
                entry.position = slotNumber
                entry.points = 0
                entry.played = 0
                entry.won = 0
                entry.drawn = 0
                entry.lost = 0
                entry.goalsFor = 0
                entry.goalsAgainst = 0
                entry.form = []
                
                db.leagueTables[dbIndex] = entry
                updatedCount += 1
            } else {
                print("⚠️ Slot introuvable : Alias='\(targetAlias)', Stage='\(stageId)', Comp='\(competitionId)'")
            }
        }
        
        db.saveLeagueTables()
        print("📊 Classement recyclé pour \(competitionId) : \(updatedCount) slots mis à jour (Stage: \(stageId)).")
    }
    
    
    // MARK: - GESTION COUPE DU TRÔNE
    
    /// Récupère les équipes qualifiées pour un tour spécifique
    func getQualifiedTeamsForCup(roundId: String) -> [String] {
        print("🏆 [DrawService] Recherche des qualifiés pour le tour : \(roundId)")
        
        // --- CAS 1 : PREMIER TOUR (1/16èmes) ---
        if roundId.contains("R32") {
            let bp1Teams = db.clubs.filter { $0.leagueId == "COMP-MAR-BP1" }.map { $0.id }
            let bp2Teams = db.clubs.filter { $0.leagueId == "COMP-MAR-BP2" }.map { $0.id }
            return bp1Teams + bp2Teams
        }
        
        // --- CAS 2 : TOURS SUIVANTS (R16, QF, SF, Finale) ---
        guard let prevId = getPreviousRoundMatchDayId(currentRoundId: roundId) else {
            print("❌ Impossible de déterminer le tour précédent pour \(roundId)")
            return []
        }
        
        let previousMatches = db.matches.filter {
            $0.matchDayId == prevId && $0.status == .played
        }
        
        if previousMatches.isEmpty {
            print("⚠️ Aucun match joué trouvé pour le tour précédent (\(prevId)).")
            return []
        }
        
        var winners: [String] = []
        for match in previousMatches {
            if let winnerId = getWinnerId(for: match) {
                winners.append(winnerId)
            }
        }
        
        let uniqueWinners = Array(Set(winners))
        print("✅ \(uniqueWinners.count) vainqueurs qualifiés depuis \(prevId).")
        return uniqueWinners
    }
    
    // --- HELPER : Déterminer le Vainqueur (Compatible Aller/Retour) ---
    private func getWinnerId(for match: Match) -> String? {
        guard let hGoals = match.homeTeamGoals,
              let aGoals = match.awayTeamGoals,
              let hId = match.homeTeamId,
              let aId = match.awayTeamId else { return nil }
        
        // 1. Tirs au but (Priorité absolue)
        if let hPen = match.homePenalties, let aPen = match.awayPenalties {
            return hPen > aPen ? hId : aId
        }
        
        // 2. Cas Match Retour (Aggrégat)
        if match.type == .secondLeg, let firstLegId = match.firstLegMatchId {
            if let firstLeg = db.matches.first(where: { $0.id == firstLegId }) {
                
                // Buts pour l'équipe à domicile CE SOIR (hId)
                var aggHome = hGoals
                if firstLeg.homeTeamId == hId { aggHome += (firstLeg.homeTeamGoals ?? 0) }
                else { aggHome += (firstLeg.awayTeamGoals ?? 0) }
                
                // Buts pour l'équipe à l'extérieur CE SOIR (aId)
                var aggAway = aGoals
                if firstLeg.homeTeamId == aId { aggAway += (firstLeg.homeTeamGoals ?? 0) }
                else { aggAway += (firstLeg.awayTeamGoals ?? 0) }
                
                if aggHome > aggAway { return hId }
                if aggAway > aggHome { return aId }
                
                return nil // Si égalité parfaite sans TAB
            }
        }
        
        // 3. Cas Match Simple
        if hGoals > aGoals { return hId }
        if aGoals > hGoals { return aId }
        
        return nil
    }
    
    // --- HELPER : Chaînage des Tours ---
    private func getPreviousRoundMatchDayId(currentRoundId: String) -> String? {
        if currentRoundId.contains("R16") { return "MD-CT-R32" }
        if currentRoundId.contains("QF")  { return "MD-CT-R16" }
        
        // ⚠️ Pour les Demies, on regarde le retour des Quarts
        if currentRoundId.contains("SF")  { return "MD-CT-QF-2" }
        
        // ⚠️ Pour la Finale, on regarde le retour des Demies
        if currentRoundId.contains("FINAL") { return "MD-CT-SF-2" }
        
        return nil
    }
    
    /// Sauvegarde finale des matchs générés par le tirage
    func saveCupFixtures(matches: [Match], roundId: String) {
        // 1. Suppression ciblée des brouillons
        // Pour QF et SF, il faut supprimer QF-1 et QF-2
        if roundId.contains("QF") {
            db.matches.removeAll { $0.matchDayId.contains("MD-CT-QF") }
        } else if roundId.contains("SF") {
            db.matches.removeAll { $0.matchDayId.contains("MD-CT-SF") }
        } else {
            // Pour R32, R16, FINAL (Match unique)
            let matchDayPrefix = getMatchDayIdForRound(roundId, leg: nil)
            db.matches.removeAll { $0.matchDayId == matchDayPrefix }
        }
        
        // 2. Ajout des nouveaux
        db.matches.append(contentsOf: matches)
        db.saveMatches()
        print("✅ \(matches.count) matchs de Coupe sauvegardés pour le tour \(roundId).")
    }
    
    private func getMatchDayIdForRound(_ roundId: String, leg: Int?) -> String {
        if roundId.contains("R32") { return "MD-CT-R32" }
        if roundId.contains("R16") { return "MD-CT-R16" }
        
        if roundId.contains("QF") {
            return (leg == 1) ? "MD-CT-QF-1" : "MD-CT-QF-2"
        }
        
        if roundId.contains("SF") {
            return (leg == 1) ? "MD-CT-SF-1" : "MD-CT-SF-2"
        }
        
        if roundId.contains("FINAL") { return "MD-CT-FINAL" }
        
        return "MD-CT-GEN"
    }
}
