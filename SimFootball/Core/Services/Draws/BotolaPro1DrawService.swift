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
    
    /// Exécute le tirage au sort complet (Génération Matchs & Journées & Classement)
    func performDraw() -> Bool {
        print("🎲 [Botola Draw] Lancement du tirage...")
        
        // 1. Récupérer la config saison actuelle
        let currentSeasonId = "S_2025_26" // TODO: Récupérer via GameState dans une vraie implémentation
        guard let config = GameDatabase.shared.getCompetitionSeason(competitionId: competitionId, seasonId: currentSeasonId) else {
            print("⚠️ Config saison introuvable.")
            return false
        }
        
        // 2. Récupérer les équipes (Objets Clubs)
        // Important : On les mélange pour que le calendrier ne soit pas alphabétique !
        let teams = config.teamIds.shuffled()
        
        guard teams.count >= 2, teams.count % 2 == 0 else {
            print("⚠️ Nombre d'équipes invalide.")
            return false
        }
        
        // 3. Algorithme Round-Robin (Berger Tables)
        let totalRounds = teams.count - 1
        let matchesPerRound = teams.count / 2
        var rounds: [[(String, String)]] = []
        
        var workingTeams = teams
        let fixedTeam = workingTeams.removeFirst()
        
        for _ in 0..<totalRounds {
            var roundMatches: [(String, String)] = []
            let lastTeam = workingTeams.last!
            roundMatches.append((fixedTeam, lastTeam))
            
            for i in 0..<(matchesPerRound - 1) {
                let home = workingTeams[i]
                let away = workingTeams[workingTeams.count - 2 - i]
                roundMatches.append((home, away))
            }
            
            rounds.append(roundMatches)
            let rotatedTeam = workingTeams.popLast()!
            workingTeams.insert(rotatedTeam, at: 0)
        }
        
        // 4. Création des Objets MatchDay et Match
        var newMatchDays: [MatchDay] = []
        var newMatches: [Match] = []
        
        // Phase Aller
        for (index, round) in rounds.enumerated() {
            let dayIndex = index + 1
            let matchDayId = "MD-BP1-J\(String(format: "%02d", dayIndex))"
            let baseDate = getDateForMatchDay(index: dayIndex)
            
            let matchDay = MatchDay(
                id: matchDayId,
                name: "Journée \(dayIndex)",
                competitionId: competitionId,
                seasonId: currentSeasonId,
                stageId: config.currentStageId,
                index: dayIndex,
                label: "Botola Pro - J\(dayIndex)",
                date: baseDate,
                isPlayed: false
            )
            newMatchDays.append(matchDay)
            
            for (matchIndex, pairing) in round.enumerated() {
                let match = Match(
                    id: "\(matchDayId)-\(matchIndex + 1)",
                    competitionId: competitionId,
                    matchDayId: matchDayId,
                    homeTeamAlias: "Team A",
                    awayTeamAlias: "Team B",
                    homeTeamId: pairing.0,
                    awayTeamId: pairing.1,
                    stadiumId: getStadiumIdForClub(pairing.0),
                    kickoffTime: baseDate,
                    status: .scheduled
                )
                newMatches.append(match)
            }
        }
        
        // Phase Retour
        for (index, round) in rounds.enumerated() {
            let dayIndex = index + 1 + totalRounds
            let matchDayId = "MD-BP1-J\(String(format: "%02d", dayIndex))"
            let baseDate = getDateForMatchDay(index: dayIndex)
            
            let matchDay = MatchDay(
                id: matchDayId,
                name: "Journée \(dayIndex)",
                competitionId: competitionId,
                seasonId: currentSeasonId,
                stageId: config.currentStageId,
                index: dayIndex,
                label: "Botola Pro - J\(dayIndex)",
                date: baseDate,
                isPlayed: false
            )
            newMatchDays.append(matchDay)
            
            for (matchIndex, pairing) in round.enumerated() {
                let match = Match(
                    id: "\(matchDayId)-\(matchIndex + 1)",
                    competitionId: competitionId,
                    matchDayId: matchDayId,
                    homeTeamAlias: "Team B",
                    awayTeamAlias: "Team A",
                    homeTeamId: pairing.1,
                    awayTeamId: pairing.0,
                    stadiumId: getStadiumIdForClub(pairing.1),
                    kickoffTime: baseDate,
                    status: .scheduled
                )
                newMatches.append(match)
            }
        }
        
        // 5. Sauvegarde Matchs & Journées
        GameDatabase.shared.matchDays.append(contentsOf: newMatchDays)
        GameDatabase.shared.matches.append(contentsOf: newMatches)
        
        // 6. GÉNÉRATION DU CLASSEMENT (Table Initiale) <--- NOUVEAU
        var newTableEntries: [LeagueTableEntry] = []
        
        // On reprend la liste originale des équipes (pour les avoir dans l'ordre, ou triées par réputation si voulu)
        // Ici on trie par nom pour avoir un classement alphabétique au départ (0 points)
        let sortedTeams = config.teamIds.sorted() // Ou trier par nom de club si on avait les objets
        
        for (index, teamId) in sortedTeams.enumerated() {
            let entry = LeagueTableEntry(
                id: "ENTRY_BP1_\(currentSeasonId)_\(teamId)",
                competitionId: competitionId,
                seasonId: currentSeasonId,
                competitionSeasonId: config.id,
                stageId: config.currentStageId,
                teamId: teamId,
                teamAlias: "T\(index + 1)_BP1", // Génération auto de l'alias demandé (T1_BP1...)
                position: index + 1, // 1 à 16
                points: 0
            )
            newTableEntries.append(entry)
        }
        
        // Ajout à la base de données
        GameDatabase.shared.leagueTables.append(contentsOf: newTableEntries)
        
        print("✅ Tirage terminé :")
        print("   - \(newMatchDays.count) Journées")
        print("   - \(newMatches.count) Matchs")
        print("   - \(newTableEntries.count) Lignes de classement initialisées")
        
        return true
    }
    
    // --- HELPERS ---
    
    private func getDateForMatchDay(index: Int) -> Date {
        let components = DateComponents(year: 2025, month: 8, day: 23, hour: 20)
        let startDate = Calendar.current.date(from: components)!
        return Calendar.current.date(byAdding: .weekOfYear, value: index - 1, to: startDate)!
    }
    
    private func getStadiumIdForClub(_ clubId: String) -> String? {
        return GameDatabase.shared.getClub(byId: clubId)?.stadiumId
    }
}
