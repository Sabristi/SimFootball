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
    /// - Parameters:
    ///   - competitionId: ID de la compétition
    ///   - seasonId: ID de la saison
    ///   - roundId: (Optionnel) ID du tour spécifique pour les Coupes (ex: "R32", "QF")
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
        
        // 2. Récupérer les MatchDays (déjà mis à jour par la transition)
        // On s'assure qu'ils sont triés (J1, J2, J3...) pour aligner avec l'algo de Berger
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
        // On parcourt les journées générées par l'algo
        for (dayIndex, dayFixtures) in fixtures.enumerated() {
            // On vérifie qu'on ne dépasse pas le nombre de journées physiques en base
            if dayIndex < matchDays.count {
                let currentDay = matchDays[dayIndex]
                
                // On récupère les indices des matchs existants pour cette journée dans la DB
                // On les trie par leur ID (ex: "BP1-J01-1", "BP1-J01-2") pour garantir l'ordre
                let matchIndices = db.matches.indices
                    .filter { db.matches[$0].matchDayId == currentDay.id }
                    .sorted { db.matches[$0].id < db.matches[$1].id }
                
                // On remplit les slots existants avec les nouvelles paires
                for (matchIndex, pair) in dayFixtures.enumerated() {
                    if matchIndex < matchIndices.count {
                        let dbIndex = matchIndices[matchIndex] // L'index réel dans le grand tableau db.matches
                        let (homeId, awayId) = pair
                        
                        // --- MISE À JOUR (RECYCLAGE) ---
                        // On modifie directement la structure existante
                        var match = db.matches[dbIndex]
                        
                        match.homeTeamId = homeId
                        match.awayTeamId = awayId
                        
                        // On met aussi à jour les alias pour garder la cohérence
                        // (Même si on utilise les IDs maintenant, c'est plus propre)
                        
                        match.stadiumId = db.getClub(byId: homeId)?.stadiumId
                        match.kickoffTime = currentDay.date // On applique la nouvelle date de la journée
                        match.status = .scheduled
                        //match.tableId = tableId
                        
                        // Reset des scores (au cas où on recycle des vieux matchs joués)
                        match.homeTeamGoals = nil
                        match.awayTeamGoals = nil
                        match.homePenalties = nil
                        match.awayPenalties = nil
                        
                        // On réinjecte la structure modifiée
                        db.matches[dbIndex] = match
                        updatedCount += 1
                    }
                }
            }
        }
        
        print("   ♻️ \(updatedCount) matchs recyclés et mis à jour.")
        
        // 5. INITIALISER LE CLASSEMENT (Toujours nécessaire car on le vide avant)
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
    
    // MARK: - 3. LOGIQUE TIRAGE COUPE (NOUVEAU)
    
    func performDrawForCup(competitionId: String, seasonId: String, roundId: String) -> Bool {
        print("🏆 [DrawService] Tirage Coupe : \(roundId)")
        
        // 1. Récupérer les équipes qualifiées
        let qualifiedTeamIds = getQualifiedTeamsForCup(roundId: roundId)
        
        guard !qualifiedTeamIds.isEmpty else {
            print("❌ Aucune équipe qualifiée trouvée pour \(roundId).")
            return false
        }
        
        // 2. Effectuer le tirage (Mélange aléatoire)
        // On mélange les IDs
        let shuffledTeams = qualifiedTeamIds.shuffled()
        var matches: [Match] = []
        
        // 3. Créer les matchs
        // On itère par paire (0-1, 2-3, etc.)
        for i in stride(from: 0, to: shuffledTeams.count - 1, by: 2) {
            let homeId = shuffledTeams[i]
            let awayId = shuffledTeams[i+1]
            
            // Récupérer les infos des clubs pour les alias/stades
            let homeClub = db.getClub(byId: homeId)
            let awayClub = db.getClub(byId: awayId)
            
            // Déterminer l'ID du MatchDay (ex: "MD-CT-R32")
            let matchDayId = getMatchDayIdForRound(roundId)
            
            // Créer l'objet Match
            // Note: Pour les coupes, type = .knockoutSingle (Match sec) ou .firstLeg (Aller/Retour)
            // Ici on simplifie en match sec (.knockoutSingle) sur terrain du premier tiré
            
            // Gérer la date précise (pour l'instant on prend celle du MatchDay ou nil)
            let kickOff = db.matchDays.first(where: { $0.id == matchDayId })?.date
            
            let newMatch = Match(
                id: UUID().uuidString, // ID unique pour le match
                competitionId: competitionId,
                matchDayId: matchDayId,
                homeTeamAlias: homeClub?.shortName ?? "Team A",
                awayTeamAlias: awayClub?.shortName ?? "Team B",
                homeTeamId: homeId,
                awayTeamId: awayId,
                stadiumId: homeClub?.stadiumId, // Joue chez le premier tiré
                kickoffTime: kickOff,
                status: .scheduled,
                type: .knockoutSingle // Match à élimination directe
            )
            
            matches.append(newMatch)
        }
        
        // 4. Sauvegarder
        saveCupFixtures(matches: matches, roundId: roundId)
        
        // ✅ 5. METTRE À JOUR LE STATUT DE LA SAISON (C'était l'oubli !)
        if let compSeason = db.getCompetitionSeason(competitionId: competitionId, seasonId: seasonId) {
                updateStatusToPlanned(compSeason: compSeason)
        } else {
                print("⚠️ Impossible de mettre à jour le statut : CompetitionSeason introuvable.")
        }
        
        return true
    }
    
    // MARK: - HELPERS PRIVES
    
    private func updateStatusToPlanned(compSeason: CompetitionSeason) {
        if let index = db.competitionSeasons.firstIndex(where: { $0.id == compSeason.id }) {
            var updated = db.competitionSeasons[index]
            updated.status = .planned
            db.competitionSeasons[index] = updated
            
            // Sauvegardes
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
    
    // MARK: - INITIALISATION DU CLASSEMENT (Table)
    
    private func initializeLeagueTable(competitionId: String, seasonId: String, teamIds: [String], tableId: String, compSeasonId: String, stageId: String) {
        
        var updatedCount = 0
        let suffix = competitionId.components(separatedBy: "-").last ?? "BP1"
        
        for (index, newTeamId) in teamIds.enumerated() {
            let slotNumber = index + 1
            let targetAlias = "T\(slotNumber)_\(suffix)"
            
            // 3. On cherche l'entrée existante
            if let dbIndex = db.leagueTables.firstIndex(where: {
                $0.competitionId == competitionId &&
                $0.stageId == stageId &&
                $0.teamAlias == targetAlias
            }) {
                
                // 4. MISE À JOUR (Recyclage)
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
                // Debug plus précis pour comprendre ce qui manque
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
            // Tout le monde (BP1 + BP2)
            let bp1Teams = db.clubs.filter { $0.leagueId == "COMP-MAR-BP1" }.map { $0.id }
            let bp2Teams = db.clubs.filter { $0.leagueId == "COMP-MAR-BP2" }.map { $0.id }
            return bp1Teams + bp2Teams
        }
        
        // --- CAS 2 : TOURS SUIVANTS (R16, QF, SF, Finale) ---
        
        // 1. Déterminer l'ID du MatchDay décisif du tour précédent
        guard let prevId = getPreviousRoundMatchDayId(currentRoundId: roundId) else {
            print("❌ Impossible de déterminer le tour précédent pour \(roundId)")
            return []
        }
        
        // 2. Récupérer les matchs joués du tour précédent
        // On utilise `contains` pour matcher "MD-CT-R32" ou "MD-CT-QF-2"
        let previousMatches = db.matches.filter {
            $0.matchDayId == prevId && $0.status == .played
        }
        
        if previousMatches.isEmpty {
            print("⚠️ Aucun match joué trouvé pour le tour précédent (\(prevId)).")
            return []
        }
        
        // 3. Extraire les vainqueurs
        var winners: [String] = []
        
        for match in previousMatches {
            // Pour chaque match terminé du tour précédent, on détermine qui passe
            if let winnerId = getWinnerId(for: match) {
                winners.append(winnerId)
            }
        }
        
        // Nettoyage des doublons (sécurité)
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
        // S'il y a eu des TAB, c'est que l'égalité (simple ou cumulée) a été brisée ici.
        if let hPen = match.homePenalties, let aPen = match.awayPenalties {
            return hPen > aPen ? hId : aId
        }
        
        // 2. Cas Match Retour (Aggrégat)
        if match.type == .secondLeg, let firstLegId = match.firstLegMatchId {
            // On doit récupérer le match aller pour faire l'addition
            if let firstLeg = db.matches.first(where: { $0.id == firstLegId }) {
                
                // Calcul des buts pour l'équipe qui est À DOMICILE AUJOURD'HUI (hId)
                var aggHome = hGoals
                if firstLeg.homeTeamId == hId { aggHome += (firstLeg.homeTeamGoals ?? 0) }
                else { aggHome += (firstLeg.awayTeamGoals ?? 0) }
                
                // Calcul des buts pour l'équipe qui est À L'EXTÉRIEUR AUJOURD'HUI (aId)
                var aggAway = aGoals
                if firstLeg.homeTeamId == aId { aggAway += (firstLeg.homeTeamGoals ?? 0) }
                else { aggAway += (firstLeg.awayTeamGoals ?? 0) }
                
                // Verdict Aggrégat
                if aggHome > aggAway { return hId }
                if aggAway > aggHome { return aId }
                
                // Si égalité parfaite ici et pas de TAB, c'est un bug de simulation,
                // mais on ne peut rien faire d'autre.
                return nil
            }
        }
        
        // 3. Cas Match Simple (Standard ou Match Aller gagné sans suite)
        // Note : Pour un match "Aller" (.firstLeg), ce code renvoie le gagnant du match,
        // mais normalement on ne devrait appeler cette fonction que sur des matchs décisifs (Retour ou Sec).
        if hGoals > aGoals { return hId }
        if aGoals > hGoals { return aId }
        
        return nil
    }
    
    // --- HELPER : Chaînage des Tours (Cible les matchs décisifs) ---
    private func getPreviousRoundMatchDayId(currentRoundId: String) -> String? {
        // R16 : Les qualifiés viennent du R32 (Match unique)
        if currentRoundId.contains("R16") { return "MD-CT-R32" }
        
        // QF : Les qualifiés viennent du R16 (Match unique)
        if currentRoundId.contains("QF")  { return "MD-CT-R16" }
        
        // SF : Les qualifiés viennent des QF (Matchs Aller-Retour)
        // ⚠️ On doit cibler le match RETOUR (QF-2) car c'est lui qui scelle le sort
        if currentRoundId.contains("SF")  { return "MD-CT-QF-2" }
        
        // Finale : Les qualifiés viennent des SF (Matchs Aller-Retour)
        // ⚠️ On doit cibler le match RETOUR (SF-2)
        if currentRoundId.contains("FINAL") { return "MD-CT-SF-2" }
        
        return nil
    }
    
    /// Sauvegarde finale des matchs générés par le tirage
    func saveCupFixtures(matches: [Match], roundId: String) {
        // 1. On supprime les éventuels brouillons pour ce round
        let matchDayPrefix = getMatchDayIdForRound(roundId) // ex: "MD-CT-R32"
        db.matches.removeAll { $0.matchDayId.starts(with: matchDayPrefix) }
        
        // 2. On ajoute les nouveaux matchs
        db.matches.append(contentsOf: matches)
        db.saveMatches()
        print("✅ \(matches.count) matchs de Coupe sauvegardés pour le tour \(roundId).")
    }
    
    private func getMatchDayIdForRound(_ roundId: String) -> String {
        // Mapping simple basé sur vos IDs JSON
        if roundId.contains("R32") { return "MD-CT-R32" }
        if roundId.contains("R16") { return "MD-CT-R16" }
        if roundId.contains("QF") { return "MD-CT-QF" } // Attention, il y a QF-1 et QF-2
        if roundId.contains("SF") { return "MD-CT-SF" }
        if roundId.contains("FINAL") { return "MD-CT-FINAL" }
        return "MD-CT-GEN"
    }
}
