//
//  Stage.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 26/11/2025.
//

import Foundation

// 1. TYPE DE STAGE
enum StageType: String, Codable {
    case league = "League"              // Championnat classique
    case groupStage = "Group Stage"     // Poules (LDC)
    case knockout = "Knockout"          // Élimination directe
    case playoffs = "Playoffs"          // Playoffs de fin de saison
    case relegationPlayoff = "Relegation Playoff" // Barrages
}

// 2. RÈGLES DE DÉPARTAGE (Tiebreakers)
// (On réutilise l'enum TieBreakerRule déjà défini dans Competition.swift si possible,
// sinon on le redéfinit ici ou on le déplace dans un fichier 'SharedModels.swift')

// 3. L'ENTITÉ STAGE
struct Stage: Identifiable, Codable, Hashable {
    let id: String                  // Ex: "STAGE_BOTOLA_REGULAR"
    
    let name: String                // "Regular Season"
    let type: StageType             // .league
    let order: Int                  // 1
    
    // Format spécifique au Stage
    let homeAndAway: Bool           // true
    let groupsCount: Int?           // null pour championnat unique, >0 pour poules
    
    // Points & Règles (Peuvent surcharger ceux de la compétition parente)
    let pointsForWin: Int
    let pointsForDraw: Int
    let pointsForLoss: Int
    let tieBreakers: [String]       // ["H2H", "GD", "GF"] (Stocké en String pour simplicité JSON)
    
    // Navigation
    let nextStageId: String?        // nil pour la Botola (c'est la fin)
    let usesTable: Bool             // true (génère un classement)
    
    // Initialiseur
    init(id: String,
         competitionSeasonId: String,
         name: String,
         type: StageType,
         order: Int,
         homeAndAway: Bool = true,
         groupsCount: Int? = nil,
         pointsForWin: Int = 3,
         pointsForDraw: Int = 1,
         pointsForLoss: Int = 0,
         tieBreakers: [String] = ["H2H", "GD", "GF"],
         nextStageId: String? = nil,
         usesTable: Bool = true) {
        
        self.id = id
        self.name = name
        self.type = type
        self.order = order
        self.homeAndAway = homeAndAway
        self.groupsCount = groupsCount
        self.pointsForWin = pointsForWin
        self.pointsForDraw = pointsForDraw
        self.pointsForLoss = pointsForLoss
        self.tieBreakers = tieBreakers
        self.nextStageId = nextStageId
        self.usesTable = usesTable
    }
}
