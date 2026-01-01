//
//  Competition.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 26/11/2025.
//

import Foundation

// MARK: - 1. Type de Compétition
enum CompetitionType: String, Codable, Hashable {
    case league = "League"          // Championnat (Botola, PL)
    case cup = "Cup"                // Coupe à élimination directe (Coupe du Trône)
    case superCup = "Super Cup"     // Match unique
    case continental = "Continental" // LDC Afrique, Europe...
    case international = "International" // Coupe du Monde, CAN
    case friendly = "Friendly"      // Matchs amicaux
}

// MARK: - 2. Portée Géographique
enum CompetitionScope: String, Codable, Hashable {
    case domestic = "Domestic"      // National (Maroc)
    case continental = "Continental" // Afrique (CAF)
    case global = "Global"          // FIFA
}

// MARK: - 3. Règles de départage (Tie Breakers)
enum TieBreakerRule: String, Codable, Hashable {
    case goalDifference = "GD"      // Différence de buts
    case goalsFor = "GF"            // Buts marqués
    case headToHead = "H2H"         // Confrontations directes (Particulier)
    case wins = "W"                 // Nombre de victoires
}

// Fréquence de la compétition
enum CompetitionFrequency: String, Codable, Hashable {
    case annual = "Annual"
    case biennial = "Biennial"
    case quadrennial = "Quadrennial"
    
    // Permet de lire "annual" (minuscule) comme "Annual" (majuscule)
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self)
        // Met la 1ère lettre en majuscule
        let capitalized = rawString.prefix(1).uppercased() + rawString.dropFirst()
        self = CompetitionFrequency(rawValue: capitalized) ?? .annual
    }
}

// MARK: - 4. Configuration du Format
struct CompetitionFormat: Codable, Hashable {
    let teamsCount: Int             // 16 pour la Botola
    let homeAndAway: Bool           // true = Aller/Retour
    
    // Points
    let pointsForWin: Int           // 3
    let pointsForDraw: Int          // 1
    let pointsForLoss: Int          // 0
    
    // Départage
    let tieBreakers: [TieBreakerRule]? // [GD, GF, H2H]
    
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

// MARK: - 5. Slots de Classement (NOUVEAU)
// Définit le type de récompense ou punition pour une position donnée
enum PositionSlotType: String, Codable, Hashable {
    case continental = "Continental" // Qualification LDC, CAF, etc.
    case promotion = "Promotion"     // Montée directe
    case relegation = "Relegation"   // Descente directe
    case promotionPlayoff = "PromotionPlayoff" // Barrage pour monter
    case relegationPlayoff = "RelegationPlayoff" // Barrage pour descendre
    case champion = "Champion"       // Titre simple (sans qualif continentale explicite)
}

struct LeaguePositionSlot: Codable, Hashable {
    let rank: Int                   // 1, 2, 15, 16...
    let type: PositionSlotType      // Le type d'action
    let targetCompetitionId: String? // "COMP-CAF-CL" ou "COMP-MAR-BP2" (nil si juste Champion)
    let label: String               // "CAF Champions League", "Relegation to D2"
    let colorHex: String?           // "#00FF00" pour Vert, "#FF0000" pour Rouge
}

// MARK: - 6. Entrée d'Historique
struct CompetitionHistoryEntry: Codable, Identifiable, Hashable {
    var id: String { competitionId + "_" + edition }
    let competitionId: String
    let edition: String             // Ex: "2024-2025"
    let winnerId: String
    let runnerUpId: String
    
    let thirdPlaceId: String?
    let semiFinalistsIds: [String]?
    let hostId: String?
}

// MARK: - 7. Mode d'affichage des lignes
enum RowDisplayMode: String, Codable, Hashable {
    case showFlags = "showFlags"         // Drapeaux (International)
    case showDivisions = "showDivisions" // Divisions (Coupes nationales)
    case showPositions = "showPositions" // Positions (Championnat)
}

// MARK: - 8. L'Entité Compétition Principale
struct Competition: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let acronym: String?
    let frequency: CompetitionFrequency
    
    // Définit durant quelles années du cycle (1, 2, 3, 4) la compétition est "Active" (Jouée)
    // Ex: CAN => [2, 4] (Années paires)
    // Ex: World Cup => [4] (Fin de cycle)
    // Ex: Ligue => [1, 2, 3, 4] (Toujours)
    let occurrenceYears: [Int]
    
    let type: CompetitionType
    let scope: CompetitionScope
    let countryId: String
    let displayRow: RowDisplayMode?
    
    let level: Int                  // 1 = D1, 2 = D2...
    let reputation: Int             // 0 à 100
    
    let confederationId: String?    // "CAF", "UEFA"
    
    // Détails visuels
    let trophyId: String?
    let titleHolderId: String?
    
    // Configuration & Règles
    let format: CompetitionFormat?
    
    // ✅ NOUVEAU : Gestion générique des places (Europe/Afrique, Montées, Descentes)
    let positionSlots: [LeaguePositionSlot]?
    
    // ✅ NOUVEAU : Hiérarchie (Système de Pyramide)
    // Seul les Ligues "Domestic" utilisent ça
    let parentCompetitionId: String?   // Ex: Pour Botola 2, c'est l'ID de Botola 1
    let childCompetitionIds: [String]? // Ex: Pour Botola 1, c'est ["ID_BOTOLA_2"]
    
    // Diffuseurs
    let broadcasters: [String]?
    
    // Historique
    var history: [CompetitionHistoryEntry]? = []
    
    // --- Computed Properties ---
    
    var logoAssetName: String { return id }
    var trophyAssetName: String { return trophyId ?? "TROPHY-\(id)" }
    var safeBroadcasters: [String] { return broadcasters ?? [] }
    
    // Initialiseur
    init(id: String,
         name: String,
         shortName: String,
         acronym: String? = nil,
         type: CompetitionType = .league,
         scope: CompetitionScope = .domestic,
         countryId: String,
         level: Int = 1,
         reputation: Int = 50,
         confederationId: String? = nil,
         titleHolderId: String? = nil,
         trophyId: String? = nil,
         format: CompetitionFormat? = nil,
         positionSlots: [LeaguePositionSlot]? = nil, // ✅ Remplacement ici
         parentCompetitionId: String? = nil,         // ✅ Ajout
         childCompetitionIds: [String]? = nil,       // ✅ Ajout
         broadcasters: [String]? = nil,
         displayRow: RowDisplayMode? = nil,
         history: [CompetitionHistoryEntry]? = nil,
         frequency: CompetitionFrequency = .annual,
         occurrenceYears: [Int]? = nil) {
        
        self.id = id
        self.name = name
        self.shortName = shortName
        self.acronym = acronym
        self.type = type
        self.scope = scope
        self.countryId = countryId
        self.level = level
        self.reputation = reputation
        self.confederationId = confederationId
        self.titleHolderId = titleHolderId
        self.trophyId = trophyId
        self.format = format
        self.positionSlots = positionSlots
        self.parentCompetitionId = parentCompetitionId
        self.childCompetitionIds = childCompetitionIds
        self.broadcasters = broadcasters
        self.displayRow = displayRow
        self.history = history ?? []
        self.frequency = frequency
        // Par défaut, si annuel, c'est [1, 2, 3, 4], sinon on prend la valeur fournie
        self.occurrenceYears = occurrenceYears ?? (frequency == .annual ? [1, 2, 3, 4] : [])
    }
    
    // ✅ Helper pour savoir si on doit la lancer cette saison
    func isActive(inCycleYear year: Int) -> Bool {
            return occurrenceYears.contains(year)
    }
}
