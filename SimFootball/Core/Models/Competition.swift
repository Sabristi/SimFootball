//
//  Competition.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 26/11/2025.
//

import Foundation

// 1. Type de Compétition
enum CompetitionType: String, Codable {
    case league = "League"          // Championnat (Botola, PL)
    case cup = "Cup"                // Coupe à élimination directe (Coupe du Trône)
    case superCup = "Super Cup"     // Match unique
    case international = "International" // Coupe du Monde, CAN
}

// 2. Portée Géographique
enum CompetitionScope: String, Codable {
    case domestic = "Domestic"      // National (Maroc)
    case continental = "Continental" // Afrique (CAF)
    case world = "World"            // FIFA
}

// 3. Règles de départage (Tie Breakers)
enum TieBreakerRule: String, Codable {
    case goalDifference = "GD"      // Différence de buts
    case goalsFor = "GF"            // Buts marqués
    case headToHead = "H2H"         // Confrontations directes (Particulier)
    case wins = "W"                 // Nombre de victoires
}

// 4. Configuration du Format (Règles du jeu)
struct CompetitionFormat: Codable, Hashable {
    let teamsCount: Int             // 16 pour la Botola
    let homeAndAway: Bool           // true = Aller/Retour
    
    // Points
    let pointsForWin: Int           // 3
    let pointsForDraw: Int          // 1
    let pointsForLoss: Int          // 0
    
    // Départage
    let tieBreakers: [TieBreakerRule] // [GD, GF, H2H]
    
    // Initialiseur avec valeurs par défaut (Standard FIFA)
    init(teamsCount: Int = 16,
         homeAndAway: Bool = true,
         pointsForWin: Int = 3,
         pointsForDraw: Int = 1,
         pointsForLoss: Int = 0,
         tieBreakers: [TieBreakerRule] = [.goalDifference, .goalsFor, .headToHead]) {
        
        self.teamsCount = teamsCount
        self.homeAndAway = homeAndAway
        self.pointsForWin = pointsForWin
        self.pointsForDraw = pointsForDraw
        self.pointsForLoss = pointsForLoss
        self.tieBreakers = tieBreakers
    }
}

// 5. Template de Qualification (Read-Only pour l'instant)
struct QualificationSlotTemplate: Codable, Hashable {
    let rank: Int                   // 1er, 2ème...
    let targetCompetitionId: String // "CAF_CL" (Ligue des Champions)
    let label: String               // "Qualification CAF CL"
    let colorHex: String            // "#00FF00" pour l'affichage dans le classement
}

// 6. L'Entité Compétition Principale
struct Competition: Identifiable, Codable, Hashable {
    let id: String                  // "COMP-MAR-BP1"
    let name: String                // "Botola Pro 1 Inwi"
    let shortName: String           // "Botola Pro 1"
    
    // Métadonnées
    let type: CompetitionType
    let scope: CompetitionScope
    let countryId: String?          // "MAR" (Optionnel si scope = Continental)
    let confederationId: String     // "CAF"
    
    // Configuration
    let format: CompetitionFormat
    
    // Qualifications (Optionnel pour V0)
    let qualificationSlots: [QualificationSlotTemplate]
    
    // Initialiseur
    init(id: String,
         name: String,
         shortName: String,
         type: CompetitionType,
         scope: CompetitionScope,
         countryId: String? = nil,
         confederationId: String,
         format: CompetitionFormat,
         qualificationSlots: [QualificationSlotTemplate] = []) {
        
        self.id = id
        self.name = name
        self.shortName = shortName
        self.type = type
        self.scope = scope
        self.countryId = countryId
        self.confederationId = confederationId
        self.format = format
        self.qualificationSlots = qualificationSlots
    }
}
