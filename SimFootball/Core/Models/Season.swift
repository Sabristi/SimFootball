//
//  Season.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 26/11/2025.
//

import Foundation

// 1. STATUT (Partagé entre Saison et Compétition)
enum SeasonStatus: String, Codable {
    case notScheduled = "Not Scheduled" // Pas encore programmé
    case planned = "Planned"            // Calendrier généré mais pas commencé
    case open = "Open"                  // En cours (Remplace "Running" pour matcher le Service)
    case closed = "Closed"              // Terminé/Archivé (Remplace "Finished")
    
    // Pour compatibilité si vous aviez "Running" ailleurs
    static let running = SeasonStatus.open
    static let finished = SeasonStatus.closed
}

// 2. SAISON GLOBALE (Le conteneur temporel)
/// Représente une année footballistique complète (ex: "2025/2026")
struct Season: Identifiable, Codable, Hashable {
    let id: String              // Ex: "S_2025_26"
    let label: String           // Ex: "2025/2026"
    
    let startDate: Date         // Ex: 01/07/2025
    let endDate: Date           // Ex: 30/06/2026
    
    var currentDate: Date       // La date simulée actuelle
    var status: SeasonStatus
    var isCurrent: Bool         // Est-ce la saison active ?
    
    var worldId: UUID?          // Lien optionnel
    
    // Initialiseur complet
    init(id: String,
         label: String,
         startDate: Date,
         endDate: Date,
         currentDate: Date? = nil,
         status: SeasonStatus = .planned, // Valeur par défaut, mais modifiable
         isCurrent: Bool = false) {
        
        self.id = id
        self.label = label
        self.startDate = startDate
        self.endDate = endDate
        self.currentDate = currentDate ?? startDate
        self.status = status
        self.isCurrent = isCurrent
    }
}

// 3. ÉDITION DE COMPÉTITION (L'instance spécifique)
/// Représente une édition d'une compétition précise pour une Season donnée.
struct CompetitionSeason: Identifiable, Codable, Hashable {
    var id: String              // Ex: "CS_BOTOLA_D1_2025_26"
    
    // Relations Parents
    var seasonId: String        // FK -> Season.id ("S_2025_26")
    let competitionId: String   // FK -> Competition.id ("COMP-MAR-BP1")
    
    // Infos
    var yearLabel: String       // "2025/26"
    var status: SeasonStatus
    
    // Dates spécifiques à cette compétition (ex: La Botola commence après la Premier League)
    // ✅ AJOUTÉ pour corriger les erreurs dans SeasonTransitionService
    var startDate: Date
    var endDate: Date
    
    // Participants
    var teamIds: [String]
    
    // Progression
    var currentStageId: String  // Ex: "STAGE_BOTOLA_REG"
    
    // Initialiseur complet
    init(id: String,
         seasonId: String,
         competitionId: String,
         currentStageId: String = "REG",
         yearLabel: String,
         startDate: Date,       // ✅ Requis maintenant
         endDate: Date,         // ✅ Requis maintenant
         status: SeasonStatus = .planned,
         teamIds: [String] = []) {
        
        self.id = id
        self.seasonId = seasonId
        self.competitionId = competitionId
        self.currentStageId = currentStageId
        self.yearLabel = yearLabel
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.teamIds = teamIds
    }
}
