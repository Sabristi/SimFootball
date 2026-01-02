//
//  SeasonCalendarModels.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import Foundation

// MARK: - 1. ENUMS & TYPES

// Fréquence de l'événement
enum EventFrequency: String, Codable {
    case annual = "Annual"          // Tous les ans (ex: Botola)
    case biennial = "Biennial"      // Tous les 2 ans (ex: CAN)
    case quadrennial = "Quadrennial" // Tous les 4 ans (ex: World Cup)
    case once = "Once"              // Une seule fois (ex: Interview spécifique)
}

// Types d'actions possibles pour un événement
enum EventActionType: String, Codable {
    case none = "None"
    case navigation = "Navigation" // Aller vers un écran (ex: Tirage au sort)
    case decision = "Decision"     // Répondre Oui/Non (ex: Interview, Offre de transfert)
    case simulation = "Simulation" // Déclencher un calcul immédiat
}

enum EventExecutionMode: String, Codable {
    case manual = "Manual"       // L'utilisateur doit cliquer (bloquant ou non)
    case automatic = "Automatic" // Le système le fait tout seul le jour J (Background)
}

// Type d'événement Calendrier
enum SeasonEventType: String, Codable {
    case draw = "Draw"              // Tirage au sort
    case transferWindow = "TransferWindow" // Mercato
    case award = "Award"            // Trophée
    case meeting = "Meeting"        // Réunion
    case email = "Email"            // Email générique
    case generic = "Event"          // Autre
}

// Type de Référence (À quoi l'événement est lié ?)
enum EventReferenceType: String, Codable {
    case competitionSeason = "CompetitionSeason"
    case stage = "Stage"
    case player = "Player"
    case none = "None"
}

// MARK: - 2. STRUCTURES

// Structure de l'action (Ce que le bouton fait)
struct EventAction: Codable, Hashable {
    let label: String           // "Effectuer le tirage"
    let type: EventActionType   // .navigation
    let targetScreen: String?   // "DrawScreen" (Identifiant de l'écran cible)
    var isCompleted: Bool       // Si l'action a été faite
    let contextData: [String: String]?
    let executionMode: EventExecutionMode? // Optionnel (défaut = .manual)
    
    init(label: String,
         type: EventActionType,
         targetScreen: String? = nil,
         isCompleted: Bool = false,
         contextData: [String : String]? = nil,
         executionMode: EventExecutionMode = .manual) {
            
            self.label = label
            self.type = type
            self.targetScreen = targetScreen
            self.isCompleted = isCompleted
            self.contextData = contextData
            self.executionMode = executionMode
    }
}

// L'Événement principal (Email / Agenda)
struct SeasonCalendarEvent: Identifiable, Codable, Hashable {
    let id: String
    var seasonId: String        // "2025-2026"
    var calendarDayId: String   // Lien vers le jour du calendrier
    
    let eventType: SeasonEventType
    let refType: EventReferenceType
    let refId: String           // ID de la compétition ou du joueur concerné
    
    let label: String
    let description: String?    // Corps du message
    var date: Date?             // Heure précise
    let colorHex: String?       // Couleur d'affichage
    
    var standardDate: Date?
    
    // NOUVEAU : Gestion de l'action
    var action: EventAction?
    
    // ✅ NOUVEAU : Gestion de la récurrence
    var frequency: EventFrequency
    
    // ✅ NOUVEAU : Années d'occurrence (pour les cycles > 1 an)
    // Ex: [2, 4] pour un événement biennal les années paires du cycle
    var occurrenceYears: [Int]?
    
    // Initialiseur complet
    init(id: String = UUID().uuidString,
         seasonId: String,
         calendarDayId: String,
         eventType: SeasonEventType,
         refType: EventReferenceType,
         refId: String,
         label: String,
         description: String? = nil,
         date: Date? = nil,
         standardDate: Date? = nil,
         colorHex: String? = nil,
         action: EventAction? = nil,
         frequency: EventFrequency = .annual, // Par défaut : Annuel
         occurrenceYears: [Int]? = nil) {     // Par défaut : Nil (donc tous les ans si annual)
        
        self.id = id
        self.seasonId = seasonId
        self.calendarDayId = calendarDayId
        self.eventType = eventType
        self.refType = refType
        self.refId = refId
        self.label = label
        self.description = description
        self.date = date
        self.standardDate = standardDate
        self.colorHex = colorHex
        self.action = action
        
        self.frequency = frequency
        self.occurrenceYears = occurrenceYears
    }
}

// MARK: - 3. JOUR DU CALENDRIER

// Représente une journée dans le calendrier global
struct SeasonCalendarDay: Identifiable, Codable, Hashable {
    // L'ID est basé sur la date pour garantir l'unicité par jour
    var id: String { date.formatted(.iso8601) }
    
    let seasonId: String
    let date: Date
    
    // Listes d'IDs pour éviter de dupliquer les objets complets
    var matchDayIds: [String] // Liste des journées de championnat (ex: "L1-J01")
    var eventIds: [String]    // Liste des événements spéciaux (Tirages, etc.)
    
    init(seasonId: String, date: Date, matchDayIds: [String] = [], eventIds: [String] = []) {
        self.seasonId = seasonId
        self.date = date
        self.matchDayIds = matchDayIds
        self.eventIds = eventIds
    }
}
