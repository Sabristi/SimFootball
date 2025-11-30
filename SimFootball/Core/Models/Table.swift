//
//  Table.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 29/11/2025.
//

import Foundation

/// Représente une ligne dans le classement (Une équipe)
struct LeagueTableEntry: Identifiable, Codable, Hashable {
    let id: String                  // Ex: "ENTRY_BP1_2526_RCA"
    
    // Contexte
    let competitionId: String       // "COMP-MAR-BP1"
    let seasonId: String            // "S_2025_26"
    let competitionSeasonId: String // "CS_BOTOLA_PRO_1_2025_26"
    let stageId: String             // "STAGE_BOTOLA_REG" (utile si plusieurs phases)
    
    // Équipe & Alias
    let teamId: String              // "CLUB-MAR-RCA"
    let teamAlias: String           // "T1_BP1" (Utilisé lors de l'init avant d'avoir les vrais noms si besoin)
    
    // Classement dynamique
    var position: Int               // 1, 2, 3... (Mis à jour après chaque journée)
    
    // Stats
    var points: Int
    var played: Int
    var won: Int
    var drawn: Int
    var lost: Int
    var goalsFor: Int
    var goalsAgainst: Int
    
    // Propriété calculée pour la différence de buts
    var goalDifference: Int {
        return goalsFor - goalsAgainst
    }
    
    // Forme récente (ex: ["W", "D", "L", "W", "W"])
    var form: [String] = []
    
    // Initialiseur
    init(id: String = UUID().uuidString,
         competitionId: String,
         seasonId: String,
         competitionSeasonId: String,
         stageId: String,
         teamId: String,
         teamAlias: String,
         position: Int,
         points: Int = 0,
         played: Int = 0,
         won: Int = 0,
         drawn: Int = 0,
         lost: Int = 0,
         goalsFor: Int = 0,
         goalsAgainst: Int = 0) {
        
        self.id = id
        self.competitionId = competitionId
        self.seasonId = seasonId
        self.competitionSeasonId = competitionSeasonId
        self.stageId = stageId
        self.teamId = teamId
        self.teamAlias = teamAlias
        self.position = position
        self.points = points
        self.played = played
        self.won = won
        self.drawn = drawn
        self.lost = lost
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
    }
}
