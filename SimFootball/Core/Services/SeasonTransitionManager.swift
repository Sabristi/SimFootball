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
        
        // 2. GESTION DU CYCLE DE 4 ANS
        let currentCycle = currentSave.currentCycleYear
        var nextCycleYear = currentCycle + 1
        if nextCycleYear > 4 { nextCycleYear = 1 } // Reset après 4 ans (Cycle Olympique/Mondial)
        
        print(" 📅 Cycle Olympique : Passage de l'année \(currentCycle) à \(nextCycleYear)")
        
        // Mise à jour et sauvegarde immédiate du nouveau cycle
        currentSave.currentCycleYear = nextCycleYear
        db.currentSave = currentSave
        
        // 3. PRÉPARATION DES IDs
        let oldSeasonId = "S_\(currentYear)_\(currentYear + 1 - 2000)"
        let nextYear = currentYear + 1
        let nextSeasonId = "S_\(nextYear)_\(nextYear + 1 - 2000)"
        let nextSeasonLabel = "\(currentYear)-\(nextYear)"
        
        // ✅ 4. TRAITEMENTS DE FIN DE SAISON (Ordre important)
        
        // A. Archiver les stats individuelles (avant que les joueurs/clubs ne bougent)
        service.archiveSeasonHistory(currentSeasonId: oldSeasonId)
        
        // B. Gérer les montées et descentes (Mise à jour des leagueId des clubs)
        service.processPromotionsAndRelegations(currentSeasonId: oldSeasonId)
        
        // C. Clôturer la saison globale actuelle et ouvrir la nouvelle
        service.closeCurrentGlobalSeason(seasonId: oldSeasonId)
        service.createNextGlobalSeason(currentYear: currentYear)
                
        // ✅ 5. TRAITEMENT DES COMPÉTITIONS (Ligues & Coupes)
        // On récupère d'abord les IDs des pays sélectionnés pour optimiser le filtre
        let selectedCountryIds = currentSave.selectedCountries.map { $0.id }
        
        // 🛠️ DEBUG & FIX : Si la liste est vide (problème de décodage), on force le MAROC
        if selectedCountryIds.isEmpty {
                    print("⚠️ [DEBUG] selectedCountries est vide (Erreur décodage ?). Utilisation du Fallback : ['MAR']")
                    //selectedCountryIds = ["MAR"]
        } else {
                    print("✅ [DEBUG] Pays sélectionnés chargés : \(selectedCountryIds)")
        }
                      
        let pastCompetitions = db.competitions.filter { comp in
                           
                    // CAS 1 : Compétition Domestique
                    if comp.scope == .domestic {
                        // On ne garde LA compétition QUE SI son pays est dans la liste des pays sélectionnés
                        return selectedCountryIds.contains(comp.countryId)
                    }
                    
                    // CAS 2 : Compétition Non-Domestique (Internationale / Continentale)
                    // (Si on arrive ici, scope != domestic)
                    
                    // 2a. Si c'est Annuel ET que ce n'est pas domestique
                    if comp.frequency == .annual && comp.scope != .domestic { return true }
                           
                    // 2b. Si c'est Cyclique (ex: World Cup, Euro), on vérifie l'année du cycle
                    return comp.occurrenceYears.contains(currentCycle)
        }
                      
        print("📋 Compétitions passées pour le cycle \(currentCycle) : \(pastCompetitions.count)")
                
        let futurCompetitions = db.competitions.filter { comp in
                           
                    // CAS 1 : Compétition Domestique
                    if comp.scope == .domestic {
                        // On ne garde LA compétition QUE SI son pays est dans la liste des pays sélectionnés
                        return selectedCountryIds.contains(comp.countryId)
                    }
                    
                    // CAS 2 : Compétition Non-Domestique (Internationale / Continentale)
                    // (Si on arrive ici, scope != domestic)
                    
                    // 2a. Si c'est Annuel ET que ce n'est pas domestique
                    if comp.frequency == .annual && comp.scope != .domestic { return true }
                           
                    // 2b. Si c'est Cyclique (ex: World Cup, Euro), on vérifie l'année du cycle
                    return comp.occurrenceYears.contains(nextCycleYear)
        }
                      
        print("📋 Compétitions passées pour le cycle \(nextCycleYear) : \(futurCompetitions.count)")
        
        
        for competition in pastCompetitions {
            print("   👉 Traitement de : \(competition.shortName)")
            
            // D. Archiver le palmarès de la compétition (Vainqueur de la saison passée)
            service.archiveCompetitionHistory(
                competitionId: competition.id,
                oldSeasonId: oldSeasonId,
                nextSeasonLabel: nextSeasonLabel
            )
            
        }
        
        for competition in futurCompetitions {
            print("   👉 Traitement de : \(competition.shortName)")
            
            // E. Rotation de la saison (Création de l'objet CompetitionSeason pour la nouvelle année)
            service.rotateCompetitionSeason(
                competitionId: competition.id,
                oldSeasonId: oldSeasonId,
                nextSeasonId: nextSeasonId,
                nextYear: nextYear
            )
            
            // F. Recyclage des journées (MatchDays) avec décalage de date intelligent
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
            
            // H. Création de l'événement de tirage au sort pour la nouvelle saison
            createDrawEvent(for: competition, nextYear: nextYear, nextSeasonId: nextSeasonId, cycleYear: nextCycleYear)
        }
        
        // 6. SAUVEGARDE FINALE DE TOUTES LES DONNÉES
        db.saveAllData()
        
        print("✅ [MANAGER] TRANSITION VERS \(nextYear) TERMINÉE AVEC SUCCÈS.\n")
    }
    
    // MARK: - CRÉATION ÉVÉNEMENT TIRAGE
    
    private func createDrawEvent(for competition: Competition, nextYear: Int, nextSeasonId: String, cycleYear: Int) {
        
        // Date par défaut du tirage (Mi-Juillet)
        var comps = DateComponents()
        comps.year = nextYear
        comps.month = 7
        comps.day = 15
        comps.hour = 12 // Midi
        let drawDate = Calendar.current.date(from: comps) ?? Date()
        
        var context: [String: String]? = nil
        var label = "Tirage : \(competition.shortName)"
        var executionMode: EventExecutionMode = .manual // Par défaut manuel pour le suspense
        
        // --- LOGIQUE SPÉCIFIQUE ---
        
        // 1. Coupes Nationales (Coupe du Trône) -> Tirage 1/16èmes
        if competition.type == .cup {
            context = ["roundId": "R32"] // On commence par les 1/16èmes
            executionMode = .automatic   // Automatique pour fluidifier le début de saison
        }
        
        // 2. Championnats (Botola) -> Tirage Calendrier
        if competition.type == .league {
            // Pas de context particulier, c'est le tirage du calendrier complet
            executionMode = .automatic
        }
        
        // 3. International (Exemple futur)
        /*
        if competition.frequency == .quadrennial {
            label = "Tirage : \(competition.name) (Phase Finale)"
            executionMode = .manual // On veut voir le tirage de la Coupe du Monde !
        }
        */
        
        // Création de l'objet Event
        let drawEvent = SeasonCalendarEvent(
            id: UUID().uuidString,
            seasonId: nextSeasonId,
            calendarDayId: drawDate.formatted(.iso8601),
            eventType: .draw,
            refType: .competitionSeason,
            refId: competition.id,
            label: label,
            description: "Tirage au sort officiel de la \(competition.name) pour la saison \(nextYear)/\(nextYear+1).",
            date: drawDate,
            colorHex: "#FFD700", // Or
            action: EventAction(
                label: "Effectuer le tirage",
                type: .navigation,
                targetScreen: "CompetitionDraw",
                isCompleted: false,
                contextData: context,
                executionMode: executionMode
            )
        )
        
        db.calendarEvents.append(drawEvent)
        print("   📅 Événement de tirage créé : \(label) (\(executionMode.rawValue))")
    }
}
