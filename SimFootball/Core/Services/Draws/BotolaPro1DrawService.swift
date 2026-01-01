//
//  BotolaPro1DrawService.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 03/12/2025.
//

import Foundation

class BotolaPro1DrawService {
    static let shared = BotolaPro1DrawService()
    
    private let competitionId = "COMP-MAR-BP1"
    
    private init() {}
    
    /// Récupère les participants
    func getParticipants(seasonId: String) -> [Club] {
        guard let config = GameDatabase.shared.getCompetitionSeason(competitionId: competitionId, seasonId: seasonId) else {
            return []
        }
        return config.teamIds.compactMap { GameDatabase.shared.getClub(byId: $0) }.sorted { $0.name < $1.name }
    }
    
    /// Exécute le tirage au sort (Mode Template)
    func performDraw() -> Bool {
        print("🎲 [Botola Draw] Lancement du tirage (Mode Template)...")
        
        // 1. Récupérer la config saison actuelle
        let currentSeasonId = "S_2025_26"
        guard let config = GameDatabase.shared.getCompetitionSeason(competitionId: competitionId, seasonId: currentSeasonId) else {
            print("⚠️ Config saison introuvable.")
            return false
        }
        
        // 2. SÉCURITÉ : Vérifier si les matchs template sont présents
        let existingMatchesCount = GameDatabase.shared.matches.filter { $0.competitionId == competitionId }.count
        
        if existingMatchesCount == 0 {
            print("⚠️ Aucun match trouvé en mémoire. Recharge du template Matches.json...")
            let allTemplateMatches: [Match] = DataLoader.load("Matches.json")
            let botolaMatches = allTemplateMatches.filter { $0.competitionId == competitionId }
            GameDatabase.shared.matches.append(contentsOf: botolaMatches)
            print("✅ \(botolaMatches.count) matchs template réinjectés en mémoire.")
        }
        
        // 3. Mélanger les équipes
        let shuffledTeams = config.teamIds.shuffled()
        
        guard shuffledTeams.count >= 16 else {
            print("⚠️ Nombre d'équipes insuffisant (Attendu 16).")
            return false
        }
        
        // 4. Créer le Dictionnaire de Mapping (Alias -> Club ID)
        var aliasMap: [String: String] = [:]
        for (index, teamId) in shuffledTeams.enumerated() {
            let alias = "T\(index + 1)_BP1"
            aliasMap[alias] = teamId
        }
        
        print("📋 Mapping généré.")
        
        // 5. MISE À JOUR DES MATCHS EXISTANTS
        var updatedCount = 0
        
        for i in 0..<GameDatabase.shared.matches.count {
            if GameDatabase.shared.matches[i].competitionId == competitionId {
                
                var match = GameDatabase.shared.matches[i]
                
                // A. Mise à jour Home Team
                if let homeAlias = match.homeTeamAlias as String?, let realHomeId = aliasMap[homeAlias] {
                    match.homeTeamId = realHomeId
                    match.stadiumId = getStadiumIdForClub(realHomeId)
                }
                
                // B. Mise à jour Away Team
                if let awayAlias = match.awayTeamAlias as String?, let realAwayId = aliasMap[awayAlias] {
                    match.awayTeamId = realAwayId
                }
                
                // C. Mise à jour Statut
                match.status = .scheduled
                
                // D. Mise à jour de la Date
                if let matchDay = GameDatabase.shared.matchDays.first(where: { $0.id == match.matchDayId }) {
                    match.kickoffTime = matchDay.date
                }
                
                // Sauvegarde
                GameDatabase.shared.matches[i] = match
                updatedCount += 1
            }
        }
        
        // 6. GÉNÉRATION DU CLASSEMENT
        // On nettoie d'abord au cas où
        GameDatabase.shared.leagueTables.removeAll { $0.competitionId == competitionId && $0.seasonId == currentSeasonId }
        
        var newTableEntries: [LeagueTableEntry] = []
        for (alias, teamId) in aliasMap {
            let position = Int(alias.replacingOccurrences(of: "T", with: "").replacingOccurrences(of: "_BP1", with: "")) ?? 0
            
            let entry = LeagueTableEntry(
                id: "ENTRY_BP1_\(currentSeasonId)_\(teamId)",
                competitionId: competitionId,
                seasonId: currentSeasonId,
                competitionSeasonId: config.id,
                stageId: config.currentStageId,
                tableId: "BP1-REG", // <--- AJOUT DE L'ID DE TABLE (Correspond à Matches.json)
                teamId: teamId,
                teamAlias: alias,
                position: position,
                points: 0
            )
            newTableEntries.append(entry)
        }
        newTableEntries.sort { $0.position < $1.position }
        GameDatabase.shared.leagueTables.append(contentsOf: newTableEntries)
        
        // 7. MISE À JOUR DU STATUT DE LA SAISON
        if let index = GameDatabase.shared.competitionSeasons.firstIndex(where: { $0.id == config.id }) {
            GameDatabase.shared.competitionSeasons[index].status = .planned
            print("✅ Statut mis à jour : Planned")
        }
        
        print("✅ Tirage terminé : \(updatedCount) matchs configurés et Table BP1-REG créée.")
        return true
    }
    
    // --- HELPERS ---
    private func getStadiumIdForClub(_ clubId: String) -> String? {
        return GameDatabase.shared.getClub(byId: clubId)?.stadiumId
    }
}
