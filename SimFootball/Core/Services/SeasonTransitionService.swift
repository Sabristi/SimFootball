//
//  SeasonTransitionService.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import Foundation

class SeasonTransitionService {
    
    static let shared = SeasonTransitionService()
    private let db = GameDatabase.shared
    
    private init() {}
    
    // MARK: - 1. GESTION SAISON GLOBALE
    
    func closeCurrentGlobalSeason(seasonId: String) {
        if let index = db.seasons.firstIndex(where: { $0.id == seasonId }) {
            var season = db.seasons[index]
            season.status = .closed
            db.seasons[index] = season
            db.saveSeasons()
            print("🔒 Saison globale \(seasonId) clôturée.")
        }
    }
    
    func createNextGlobalSeason(currentYear: Int) {
        let nextYear = currentYear + 1
        let nextSeasonId = "S_\(nextYear)_\(nextYear + 1 - 2000)"
        let label = "\(nextYear)/\(nextYear + 1 - 2000)"
        
        let newSeason = Season(
            id: nextSeasonId,
            label: label,
            startDate: getDate(year: nextYear, month: 8, day: 1),
            endDate: getDate(year: nextYear + 1, month: 6, day: 30),
            status: .open
        )
        
        db.seasons.append(newSeason)
        db.saveSeasons()
        
        if var save = db.currentSave {
            save.currentSeasonId = nextSeasonId
            save.currentDate = newSeason.startDate
            db.currentSave = save
        }
        
        print("✨ Nouvelle saison globale créée : \(nextSeasonId)")
    }
    
    // MARK: - 1.2 GESTION PROMOTIONS / RELÉGATIONS (NOUVEAU)
    // ✅ Fonction à appeler AVANT rotateCompetitionSeason
    func processPromotionsAndRelegations(currentSeasonId: String) {
        print("🔃 Traitement des montées et descentes pour la saison \(currentSeasonId)...")
        
        // On récupère toutes les ligues
        let leagues = db.competitions.filter { $0.type == .league }
        
        // Liste temporaire pour stocker les mouvements avant de les appliquer
        var movements: [(teamId: String, newLeagueId: String, teamName: String, reason: String)] = []
        
        for league in leagues {
            // 1. Récupérer le classement final
            let table = db.getLeagueTable(competitionId: league.id, seasonId: currentSeasonId)
            
            // 2. Vérifier les règles (Slots)
            guard let slots = league.positionSlots else { continue }
            
            for entry in table {
                // Est-ce que ce rang a une règle de mouvement ?
                if let slot = slots.first(where: { $0.rank == entry.position }) {
                    
                    // On ne traite que Promotion et Relegation (On ignore Continental pour le changement de ligue)
                    if (slot.type == .promotion || slot.type == .relegation),
                       let targetId = slot.targetCompetitionId {
                        
                        // On récupère le nom du club pour les logs
                        let clubName = db.getClub(byId: entry.teamId)?.name ?? entry.teamAlias
                        
                        movements.append((
                            teamId: entry.teamId,
                            newLeagueId: targetId,
                            teamName: clubName,
                            reason: slot.label
                        ))
                    }
                }
            }
        }
        
        // 3. APPLIQUER LES MOUVEMENTS
        for move in movements {
            if let index = db.clubs.firstIndex(where: { $0.id == move.teamId }) {
                var club = db.clubs[index]
                let oldLeagueId = club.leagueId
                
                // Mise à jour de la ligue
                club.leagueId = move.newLeagueId
                db.clubs[index] = club
                
                print("   👉 \(move.teamName) : \(oldLeagueId) -> \(move.newLeagueId) (\(move.reason))")
            }
        }
        
        // 4. SAUVEGARDE
        if !movements.isEmpty {
            // On sauvegarde le fichier Clubs.json car la propriété leagueId a changé
            db.saveClubs()
            print("✅ \(movements.count) équipes ont changé de division.")
        } else {
            print("ℹ️ Aucune promotion/relégation détectée.")
        }
    }
    
    // MARK: - 1.5 ARCHIVAGE HISTORIQUE ÉQUIPES (PALMARÈS)
    
    func archiveSeasonHistory(currentSeasonId: String) {
        print("📚 Archivage du palmarès individuel des équipes pour \(currentSeasonId)...")
        
        let allClubs = db.clubs
        var newHistories: [TeamSeasonHistory] = []
        
        for club in allClubs {
            var performances: [CompetitionPerformance] = []
            
            // A. CHAMPIONNATS (League Tables)
            let tables = db.leagueTables.filter { $0.seasonId == currentSeasonId && $0.teamId == club.id }
            
            for entry in tables {
                let isChamp = entry.position == 1
                let isRelegated = entry.position >= 15 // Fallback simple si pas de slot
                let isQualified = entry.position <= 2
                
                // Récupération des infos précises via les slots si dispo
                var preciseRelegation = isRelegated
                var precisePromotion = false
                var preciseContinental = isQualified
                
                if let comp = db.competitions.first(where: { $0.id == entry.competitionId }),
                   let slots = comp.positionSlots,
                   let slot = slots.first(where: { $0.rank == entry.position }) {
                    
                    if slot.type == .relegation { preciseRelegation = true }
                    if slot.type == .promotion { precisePromotion = true }
                    if slot.type == .continental { preciseContinental = true }
                }
                
                let perf = CompetitionPerformance(
                    competitionId: entry.competitionId,
                    rankLabel: ordinal(entry.position),
                    preciseRank: entry.position,
                    roundReachedId: nil,
                    matchesPlayed: entry.played,
                    wins: entry.won,
                    draws: entry.drawn,
                    losses: entry.lost,
                    points: entry.points,
                    isWinner: isChamp,
                    isPromoted: precisePromotion,
                    isRelegated: preciseRelegation,
                    isContinentalQualified: preciseContinental
                )
                performances.append(perf)
            }
            
            // C. CRÉATION DE L'ENTRÉE SAISON
            if !performances.isEmpty {
                let label = currentSeasonId
                    .replacingOccurrences(of: "S_", with: "")
                    .replacingOccurrences(of: "_", with: "/")
                
                let history = TeamSeasonHistory(
                    id: UUID().uuidString,
                    teamId: club.id,
                    seasonId: currentSeasonId,
                    yearLabel: label,
                    performances: performances,
                    totalGoalsScored: tables.reduce(0) { $0 + $1.goalsFor },
                    totalGoalsConceded: tables.reduce(0) { $0 + $1.goalsAgainst },
                    topScorerName: nil,
                    averageAttendance: nil
                )
                newHistories.append(history)
            }
        }
        
        db.teamHistories.append(contentsOf: newHistories)
        print("✅ Historique individuel généré pour \(newHistories.count) clubs.")
    }
    
    // MARK: - 2. HISTORIQUE COMPÉTITION (Sauvegarde)
    
    func archiveCompetitionHistory(competitionId: String, oldSeasonId: String, nextSeasonLabel: String) {
        let table = db.getLeagueTable(competitionId: competitionId, seasonId: oldSeasonId)
        guard !table.isEmpty else { return }
        
        let winnerId = table[0].teamId
        let runnerUpId = table.count >= 2 ? table[1].teamId : "UNKNOWN"
        let thirdPlaceId = table.count >= 3 ? table[2].teamId : nil
        
        let entry = CompetitionHistoryEntry(
            competitionId: competitionId,
            edition: nextSeasonLabel,
            winnerId: winnerId,
            runnerUpId: runnerUpId,
            thirdPlaceId: thirdPlaceId,
            semiFinalistsIds: nil,
            hostId: nil
        )
        
        if db.currentSave != nil {
            db.currentSave?.competitionHistory.append(entry)
            print(" 🏆 Historique archivé pour \(competitionId) dans la sauvegarde.")
        }
    }
    
    // MARK: - 3. ROTATION COMPETITION SEASON
    
    func rotateCompetitionSeason(competitionId: String, oldSeasonId: String, nextSeasonId: String, nextYear: Int) {
        guard let index = db.competitionSeasons.firstIndex(where: { $0.competitionId == competitionId && $0.seasonId == oldSeasonId }) else {
            return
        }
        
        var compSeason = db.competitionSeasons[index]
        guard let competition = db.competitions.first(where: { $0.id == competitionId }) else { return }
        
        let nextYearShort = nextYear + 1 - 2000
        let newId = "CS_\(competition.shortName.replacingOccurrences(of: " ", with: "_").uppercased())_\(nextYear)_\(nextYearShort)"
        
        // ✅ Mise à jour critique : On filtre les clubs qui ont le "leagueId" actuel
        // Comme on a exécuté "processPromotionsAndRelegations" AVANT,
        // les promus ont déjà leur nouveau leagueId, donc ils seront inclus ici automatiquement !
        let teamIds: [String] = db.clubs
            .filter { $0.leagueId == competitionId }
            .map { $0.id }
        
        compSeason.id = newId
        compSeason.seasonId = nextSeasonId
        compSeason.yearLabel = "\(nextYear)/\(nextYearShort)"
        compSeason.startDate = getDate(year: nextYear, month: 8, day: 20)
        compSeason.endDate = getDate(year: nextYear + 1, month: 5, day: 30)
        compSeason.status = .notScheduled
        compSeason.teamIds = teamIds
        
        db.competitionSeasons[index] = compSeason
        db.saveCompetitionSeasons()
        
        print(" 🔄 CompetitionSeason recyclée pour \(competitionId). Nouvel ID: \(newId). Équipes: \(teamIds.count)")
    }
    
    // MARK: - 4. GÉNÉRATION DES MATCH DAYS
    
    func recycleMatchDays(competitionId: String, oldSeasonId: String, nextSeasonId: String) {
        var updatedCount = 0
        
        for i in db.matchDays.indices {
            if db.matchDays[i].competitionId == competitionId && db.matchDays[i].seasonId == oldSeasonId {
                
                let currentMatchDayDate = db.matchDays[i].date
                let standardDate = db.matchDays[i].standardDate
                                
                // ✅ CALCUL DE LA NOUVELLE DATE
                // On projette la date actuelle +1 an, puis on l'aligne sur le jour de la semaine de la standardDate
                let newDate = calculateDateForNextYear(currentDate: currentMatchDayDate, standardDate: standardDate)
                
                db.matchDays[i].seasonId = nextSeasonId
                db.matchDays[i].date = newDate
                db.matchDays[i].isPlayed = false
                
                updatedCount += 1
            }
        }
        
        print(" ♻️ \(updatedCount) Journées recyclées pour \(competitionId).")
    }
    
    // MARK: - 5. RESET MATCHS
    
    func resetMatchesForNewSeason(competitionId: String, oldSeasonId: String, nextSeasonId: String) {
        print(" ℹ️ Les matchs seront générés lors du tirage au sort.")
    }
    
    // MARK: - HELPERS
    
    private func getDate(year: Int, month: Int, day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return Calendar.current.date(from: comps) ?? Date()
    }
    
    // MARK: - HELPERS DATES
        
    /// Calcule la date de la saison prochaine en se basant sur la Date Standard pour éviter la dérive
    private func calculateDateForNextYear(currentDate: Date, standardDate: Date) -> Date {
            let calendar = Calendar.current
            
            // 1. Déterminer l'année cible
            // On prend l'année du match qui vient de se jouer et on ajoute 1
            let currentYear = calendar.component(.year, from: currentDate)
            let targetYear = currentYear + 1
            
            // 2. Projeter la DATE STANDARD sur l'année cible
            // Au lieu d'ajouter 1 an à "currentDate" (qui a peut-être déjà bougé),
            // on repart de la source : "Le 15 Juillet" de l'année cible.
            var comps = calendar.dateComponents([.day, .month], from: standardDate)
            comps.year = targetYear
            
            // (On garde l'heure de la standardDate pour être propre)
            comps.hour = calendar.component(.hour, from: standardDate)
            comps.minute = calendar.component(.minute, from: standardDate)
            
            guard let anniversaryDate = calendar.date(from: comps) else { return currentDate }
            
            // 3. Récupérer le jour de la semaine CIBLE (ex: Mardi)
            // C'est celui de la standardDate originale
            let targetWeekday = calendar.component(.weekday, from: standardDate)
            
            // 4. Récupérer le jour de la semaine de l'ANNIVERSAIRE (ex: 15/07/2030)
            let anniversaryWeekday = calendar.component(.weekday, from: anniversaryDate)
            
            // 5. Calcul de la différence
            var diff = targetWeekday - anniversaryWeekday
            
            // 6. ALGORITHME DE PROXIMITÉ (+/- 3 jours Max)
            // On cherche le chemin le plus court pour retrouver le jour de la semaine cible.
            
            if diff > 3 {
                diff -= 7 // Ex: On veut Mardi (3), on est Samedi (7). Diff = -4. C'est > 3 ? Non.
                          // Ex inverse : On veut Samedi (7), on est Mardi (3). Diff = 4. 4 > 3 -> 4-7 = -3. On recule de 3 jours.
            } else if diff < -3 {
                diff += 7 // Ex: On veut Mardi (3), on est Samedi (7). Diff = -4. -4 < -3 -> -4+7 = +3. On avance de 3 jours.
            }
            
            // 7. On applique le décalage à la date ANNIVERSAIRE (pas à la currentDate)
            // Résultat garanti : 15/07 +/- 3 jours max.
            return calendar.date(byAdding: .day, value: diff, to: anniversaryDate) ?? anniversaryDate
    }
    
    private func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
