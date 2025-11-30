import Foundation

// 1. Types d'actions possibles pour un événement
enum EventActionType: String, Codable {
    case none = "None"
    case navigation = "Navigation" // Aller vers un écran (ex: Tirage au sort)
    case decision = "Decision"     // Répondre Oui/Non (ex: Interview, Offre de transfert)
    case simulation = "Simulation" // Déclencher un calcul immédiat
}

// 2. Structure de l'action
struct EventAction: Codable, Hashable {
    let label: String           // "Effectuer le tirage"
    let type: EventActionType   // .navigation
    let targetScreen: String?   // "DrawScreen" (Identifiant de l'écran cible)
    var isCompleted: Bool       // Si l'action a été faite
}

// 3. Mise à jour de l'Événement
struct SeasonCalendarEvent: Identifiable, Codable, Hashable {
    let id: String
    let seasonId: String
    let calendarDayId: String
    
    let eventType: SeasonEventType
    let refType: EventReferenceType
    let refId: String
    
    let label: String
    let description: String? // Un peu plus de texte pour l'email
    let time: Date?
    let colorHex: String?
    
    // NOUVEAU : Gestion de l'action
    var action: EventAction?
    
    init(id: String = UUID().uuidString,
         seasonId: String,
         calendarDayId: String,
         eventType: SeasonEventType,
         refType: EventReferenceType,
         refId: String,
         label: String,
         description: String? = nil,
         time: Date? = nil,
         colorHex: String? = nil,
         action: EventAction? = nil) {
        
        self.id = id
        self.seasonId = seasonId
        self.calendarDayId = calendarDayId
        self.eventType = eventType
        self.refType = refType
        self.refId = refId
        self.label = label
        self.description = description
        self.time = time
        self.colorHex = colorHex
        self.action = action
    }
}

// 1. Type d'événement Calendrier
enum SeasonEventType: String, Codable {
    case draw = "Draw"              // Tirage au sort
    case transferWindow = "TransferWindow" // Mercato
    case award = "Award"            // Trophée
    case meeting = "Meeting"        // Réunion
    // Note: Match et MatchDay ne sont plus ici, ils ont leur propre logique
}

// 2. Type de Référence
enum EventReferenceType: String, Codable {
    case competitionSeason = "CompetitionSeason"
    case stage = "Stage"
    case player = "Player"
    case none = "None"
}


// 4. JOUR DU CALENDRIER (La structure mise à jour)
struct SeasonCalendarDay: Identifiable, Codable, Hashable {
    var id: String { date.formatted(.iso8601) } // ID calculé pour unicité
    let seasonId: String
    let date: Date
    
    // --- TA MODIFICATION ARCHITECTURALE ---
    var matchDayIds: [String] // Liste spécifique pour les journées de championnat (ex: "L1-J01")
    var eventIds: [String]    // Liste pour les autres événements (Tirages, etc.)
    
    init(id: String? = nil, seasonId: String, date: Date, matchDayIds: [String] = [], eventIds: [String] = []) {
        self.seasonId = seasonId
        self.date = date
        self.matchDayIds = matchDayIds
        self.eventIds = eventIds
    }
}
