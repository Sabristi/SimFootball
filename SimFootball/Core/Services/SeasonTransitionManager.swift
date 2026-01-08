//
//  SeasonTransitionManager.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import Foundation

class SeasonTransitionManager {
    
    static let shared = SeasonTransitionManager()
    private let service = SeasonTransitionService.shared
    private let db = GameDatabase.shared
    
    private init() {}
    
    func processSeasonTransition(currentYear: Int) {
        print("\n🔄 [MANAGER] DÉBUT DE LA TRANSITION VERS \(currentYear + 1)...")
        
        // 1. SÉCURITÉ : Vérifier qu'une sauvegarde est chargée
        guard var currentSave = db.currentSave else {
            print("❌ Erreur critique : Aucune sauvegarde active trouvée.")
            return
        }
        
        // 2. GESTION DU CYCLE DE 4 ANS (Mondial, Euro, JO...)
        let currentCycle = currentSave.currentCycleYear
        var nextCycleYear = currentCycle + 1
        if nextCycleYear > 4 { nextCycleYear = 1 }
        
        print(" 📅 Cycle Olympique : Passage de l'année \(currentCycle) à \(nextCycleYear)")
        
        // Mise à jour et sauvegarde immédiate du nouveau cycle
        currentSave.currentCycleYear = nextCycleYear
        db.currentSave = currentSave
        
        // 3. PRÉPARATION DES IDs
        let oldSeasonId = "S_\(currentYear)_\(currentYear + 1 - 2000)"
        let nextYear = currentYear + 1
        let nextSeasonId = "S_\(nextYear)_\(nextYear + 1 - 2000)"
        let nextSeasonLabel = "\(currentYear)-\(nextYear)"
        
        // ✅ 4. SÉLECTION DES COMPÉTITIONS
        let selectedCountryIds = currentSave.selectedCountries.map { $0.id }
        
        if selectedCountryIds.isEmpty {
            print("⚠️ [DEBUG] selectedCountries est vide (Erreur décodage ?)")
        } else {
            print("✅ [DEBUG] Pays sélectionnés chargés : \(selectedCountryIds)")
        }
        
        // A. Compétitions de la saison qui se termine (pour l'archivage)
        let pastCompetitions = db.competitions.filter { comp in
            if comp.scope == .domestic {
                return selectedCountryIds.contains(comp.countryId)
            }
            if comp.frequency == .annual && comp.scope != .domestic { return true }
            return comp.occurrenceYears.contains(currentCycle)
        }
        
        // B. Compétitions de la saison qui arrive (pour la préparation)
        let futurCompetitions = db.competitions.filter { comp in
            if comp.scope == .domestic {
                return selectedCountryIds.contains(comp.countryId)
            }
            if comp.frequency == .annual && comp.scope != .domestic { return true }
            return comp.occurrenceYears.contains(nextCycleYear)
        }
        
        print("📋 Compétitions passées (Cycle \(currentCycle)) : \(pastCompetitions.count)")
        print("📋 Compétitions futures (Cycle \(nextCycleYear)) : \(futurCompetitions.count)")
        
        
        // ✅ 5. TRAITEMENTS DE FIN DE SAISON (Ordre CRITIQUE)
        
        // A. ARCHIVAGE PALMARÈS COMPÉTITIONS (EN PREMIER)
        // Indispensable de le faire AVANT l'historique des équipes pour que les vainqueurs de coupe soient connus.
        for competition in pastCompetitions {
            print("   👉 Archivage Palmarès Compétition : \(competition.shortName)")
            
            service.archiveCompetitionHistory(
                competitionId: competition.id,
                oldSeasonId: oldSeasonId,
                nextSeasonLabel: nextSeasonLabel
            )
            
            // Nettoyage des matchs de coupe (pour alléger la sauvegarde)
            // On garde les championnats pour les stats détaillées si besoin, mais les coupes sont souvent one-shot.
            if competition.type == .cup && competition.scope == .domestic {
                service.cleanUpSeasonMatches(competitionId: competition.id, seasonId: oldSeasonId)
            }
        }
        
        // B. ARCHIVAGE PALMARÈS INDIVIDUEL (ENSUITE)
        // Génère l'historique de chaque club (Championnat + Coupe via l'historique global)
        service.archiveSeasonHistory(currentSeasonId: oldSeasonId)
        
        // C. GESTION DES MONTÉES / DESCENTES
        // Modifie les leagueId des clubs pour la saison prochaine
        service.processPromotionsAndRelegations(currentSeasonId: oldSeasonId)
        
        // D. CLÔTURE SAISON GLOBALE
        // Ferme l'objet Saison S_2025_26 et crée S_2026_27
        service.closeCurrentGlobalSeason(seasonId: oldSeasonId)
        service.createNextGlobalSeason(currentYear: currentYear)
        
        
        // ✅ 6. PRÉPARATION DE LA NOUVELLE SAISON
        
        for competition in futurCompetitions {
            print("   👉 Préparation de : \(competition.shortName)")
            
            // E. Rotation de la saison (Création de l'objet CompetitionSeason)
            service.rotateCompetitionSeason(
                competitionId: competition.id,
                oldSeasonId: oldSeasonId,
                nextSeasonId: nextSeasonId,
                nextYear: nextYear
            )
            
            // F. Recyclage des journées (MatchDays) avec décalage intelligent des dates
            service.recycleMatchDays(
                competitionId: competition.id,
                oldSeasonId: oldSeasonId,
                nextSeasonId: nextSeasonId
            )
            
            // G. Reset des matchs (Suppression des scores, statuts...)
            service.resetMatchesForNewSeason(
                competitionId: competition.id,
                oldSeasonId: oldSeasonId,
                nextSeasonId: nextSeasonId
            )
        }
        
        // ✅ 7. RECYCLAGE GLOBAL DES ÉVÉNEMENTS (CALENDRIER)
        // On génère de nouveaux événements (avec nouveaux IDs pour le badge "Non Lu")
        service.recycleSeasonCalendarEvents(
            oldSeasonId: oldSeasonId,
            nextSeasonId: nextSeasonId,
            nextCycleYear: nextCycleYear
        )
        
        // 8. SAUVEGARDE FINALE
        db.saveAllData()
        
        print("✅ [MANAGER] TRANSITION VERS \(nextYear) TERMINÉE AVEC SUCCÈS.\n")
    }
}
