//
//  Season.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 26/11/2025.
//

import Foundation

// 1. STATUT (Partagé entre Saison et Compétition)
enum SeasonStatus: String, Codable {
    case notscheduled = "Not Scheduled" // Pas encore programmé
    case planned = "Planned"       // Pas encore commencé (Calendrier généré mais pas joué)
    case running = "Running"       // En cours de simulation
    case finished = "Finished"     // Terminé (Champion couronné, archivé)
}

// 2. SAISON GLOBALE (Le conteneur temporel)
/// Représente une année footballistique complète (ex: "2025/2026")
/// Elle agit comme le métronome pour toutes les compétitions du monde.
struct Season: Identifiable, Codable, Hashable {
    let id: String              // Ex: "S_2025_26"
    let label: String           // Ex: "2025/2026"
    
    let startDate: Date         // Ex: 01/07/2025
    let endDate: Date           // Ex: 30/06/2026
    
    var currentDate: Date       // La date simulée actuelle pour l'ensemble du monde cette saison
    var status: SeasonStatus
    var isCurrent: Bool         // Est-ce la saison active du GameState ?
    
    var worldId: UUID?          // Lien optionnel vers l'univers de jeu
    
    // Initialiseur
    init(id: String,
         label: String,
         startDate: Date,
         endDate: Date,
         currentDate: Date? = nil,
         isCurrent: Bool = false) {
        
        self.id = id
        self.label = label
        self.startDate = startDate
        self.endDate = endDate
        self.currentDate = currentDate ?? startDate
        self.status = .planned
        self.isCurrent = isCurrent
    }
}

// 3. ÉDITION DE COMPÉTITION (L'instance spécifique)
/// Représente une édition d'une compétition précise pour une Season donnée.
/// Ex: "Botola Pro 1 - Édition 2025/26"
struct CompetitionSeason: Identifiable, Codable, Hashable {
    let id: String              // Ex: "CS_BOTOLA_D1_2025_26"
    
    // Relations Parents
    let seasonId: String        // FK -> Season.id ("S_2025_26")
    let competitionId: String   // FK -> Competition.id ("COMP-MAR-BP1")
    
    // Infos
    let yearLabel: String       // "2025/26" (Copie pratique pour l'affichage)
    var status: SeasonStatus
    
    // Participants (IDs des clubs engagés cette année-là)
    var teamIds: [String]
    
    // Progression (Placeholder pour l'instant)
    var currentStageId: String // ID de la phase en cours (ex: "STAGE_J1", "STAGE_POULES")
    
    // Initialiseur
    init(id: String,
         seasonId: String,
         competitionId: String,
         yearLabel: String,
         teamIds: [String] = []) {
        
        self.id = id
        self.seasonId = seasonId
        self.competitionId = competitionId
        self.yearLabel = yearLabel
        self.status = .planned
        self.teamIds = teamIds
        self.currentStageId = "REG"
    }
}
