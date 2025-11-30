import Foundation

// 1. Statut du Match
enum MatchStatus: String, Codable {
    case scheduled = "Scheduled"        // Date fixée
    case notScheduled = "Not Scheduled" // Date non définie
    case played = "Played"              // Terminé
    case postponed = "Postponed"        // Reporté
    case live = "Live"                  // En cours
}

// 2. Entité Journée (MatchDay) - INCHANGÉE
struct MatchDay: Identifiable, Codable, Hashable {
    let id: String
    
    // Contexte Compétition
    let name: String
    let competitionId: String
    let seasonId: String
    let stageId: String
    
    // Info
    let index: Int
    let label: String
    let date: Date
    var isPlayed: Bool
    
    init(id: String,
         name: String,
         competitionId: String,
         seasonId: String,
         stageId: String,
         index: Int,
         label: String,
         date: Date,
         isPlayed: Bool = false) {
        
        self.id = id
        self.name = name
        self.competitionId = competitionId
        self.seasonId = seasonId
        self.stageId = stageId
        self.index = index
        self.label = label
        self.date = date
        self.isPlayed = isPlayed
    }
}

// 3. Entité Match - ADAPTÉE V0
struct Match: Identifiable, Codable, Hashable {
    let id: String                  // Ex: "BP1-J01-1"
    
    // Contexte
    let competitionId: String       // "COMP-MAR-BP1"
    let matchDayId: String          // "BP1-J01"
    let tableId: String?            // "BP1-REG" (Classement associé)
    
    // Équipes
    let homeTeamAlias: String       // "T5_BP1" (Utilisé pour le tirage)
    let awayTeamAlias: String       // "T6_BP1"
    var homeTeamId: String?         // ID Réel du club (Peut être nil avant tirage)
    var awayTeamId: String?         // ID Réel du club
    
    // Info Match
    var stadiumId: String?          // Stade (Optionnel)
    var kickoffTime: Date?          // Date précise (Optionnelle si "Not Scheduled")
    var status: MatchStatus
    
    // Détails Sportifs
    var rivalityId: String?         // Gestion des derbys
    var refereeId: String?          // Arbitre
    let isPlayingHome: Bool         // true = Le homeTeam reçoit vraiment
    
    // Score (Optionnels car vide avant le match)
    var homeTeamGoals: Int?
    var awayTeamGoals: Int?
    
    // Penalties (Pour les coupes)
    var homePenalties: Int?
    var awayPenalties: Int?
    
    // Initialiseur Complet
    init(id: String = UUID().uuidString,
         competitionId: String,
         matchDayId: String,
         homeTeamAlias: String,
         awayTeamAlias: String,
         homeTeamId: String? = nil,
         awayTeamId: String? = nil,
         stadiumId: String? = nil,
         kickoffTime: Date? = nil,
         rivalityId: String? = nil,
         tableId: String? = nil,
         homeTeamGoals: Int? = nil,
         awayTeamGoals: Int? = nil,
         homePenalties: Int? = nil,
         awayPenalties: Int? = nil,
         refereeId: String? = nil,
         isPlayingHome: Bool = true,
         status: MatchStatus = .notScheduled) {
        
        self.id = id
        self.competitionId = competitionId
        self.matchDayId = matchDayId
        self.homeTeamAlias = homeTeamAlias
        self.awayTeamAlias = awayTeamAlias
        self.homeTeamId = homeTeamId
        self.awayTeamId = awayTeamId
        self.stadiumId = stadiumId
        self.kickoffTime = kickoffTime
        self.rivalityId = rivalityId
        self.tableId = tableId
        self.homeTeamGoals = homeTeamGoals
        self.awayTeamGoals = awayTeamGoals
        self.homePenalties = homePenalties
        self.awayPenalties = awayPenalties
        self.refereeId = refereeId
        self.isPlayingHome = isPlayingHome
        self.status = status
    }
    
    // Helper d'affichage du score
    var scoreString: String {
        if status == .played, let h = homeTeamGoals, let a = awayTeamGoals {
            if let hp = homePenalties, let ap = awayPenalties {
                return "\(h) - \(a) (\(hp)-\(ap) tab)"
            }
            return "\(h) - \(a)"
        } else {
            return "v"
        }
    }
}
