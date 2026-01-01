import Foundation

// MARK: - 1. Statut du Match
enum MatchStatus: String, Codable {
    case scheduled = "Scheduled"        // Date fixée
    case notScheduled = "Not Scheduled" // Date non définie
    case played = "Played"              // Terminé
    case postponed = "Postponed"        // Reporté
    case live = "Live"                  // En cours
}

// MARK: - 2. Type de Rencontre (NOUVEAU)
// Définit les règles de décision du vainqueur
enum MatchType: String, Codable {
    case league = "League"                  // Standard (90 min, nul possible)
    case knockoutSingle = "Knockout"        // Coupe (Vainqueur obligatoire : Prolo + TAB)
    case firstLeg = "First Leg"             // Match Aller (90 min, nul possible)
    case secondLeg = "Second Leg"           // Match Retour (Aggrégat détermine Prolo + TAB)
}

// MARK: - 3. Entité Journée (MatchDay)
struct MatchDay: Identifiable, Codable, Hashable {
    let id: String
    
    // Contexte Compétition
    let name: String
    let competitionId: String
    var seasonId: String
    let stageId: String
    
    // Info
    let index: Int
    let label: String
    var date: Date
    var isPlayed: Bool
    
    var standardDate: Date
    
    init(id: String,
         name: String,
         competitionId: String,
         seasonId: String,
         stageId: String,
         index: Int,
         label: String,
         date: Date,
         standardDate: Date? = nil,
         isPlayed: Bool = false) {
        
        self.id = id
        self.name = name
        self.competitionId = competitionId
        self.seasonId = seasonId
        self.stageId = stageId
        self.index = index
        self.label = label
        self.date = date
        self.standardDate = standardDate ?? date
        self.isPlayed = isPlayed
    }
}

// MARK: - 4. Entité Match (MISE À JOUR COMPLÈTE)
struct Match: Identifiable, Codable, Hashable {
    let id: String                  // Ex: "BP1-J01-1"
    
    // Contexte
    let competitionId: String       // "COMP-MAR-BP1"
    let matchDayId: String          // "BP1-J01"
    let tableId: String?            // "BP1-REG" (Classement associé)
    
    // Configuration du match (✅ NOUVEAU)
    var type: MatchType                     // Défaut : .league
    var firstLegMatchId: String?            // ID du match aller (requis si type == .secondLeg)
    
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
    
    // Penalties (Pour les coupes / Retours)
    var homePenalties: Int?
    var awayPenalties: Int?
    
    // Indique si le match est allé en prolongation (✅ NOUVEAU : utile pour l'affichage "a.p.")
    var wasExtraTimePlayed: Bool?
    
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
         status: MatchStatus = .notScheduled,
         
         // Nouveaux paramètres avec valeurs par défaut pour compatibilité
         type: MatchType = .league,
         firstLegMatchId: String? = nil,
         wasExtraTimePlayed: Bool = false) {
        
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
        
        // Initialisation des nouveaux champs
        self.type = type
        self.firstLegMatchId = firstLegMatchId
        self.wasExtraTimePlayed = wasExtraTimePlayed
    }
    
    // Helper d'affichage du score (Mis à jour pour afficher a.p.)
    var scoreString: String {
        // Si le match n'est pas joué ou pas de score, on affiche "v" (versus)
        guard status == .played, let h = homeTeamGoals, let a = awayTeamGoals else {
            return "v"
        }
        
        // Score de base (ex: "2 - 1")
        var baseScore = "\(h) - \(a)"
        
        // Ajout de la mention "a.p." si prolongations jouées
        if wasExtraTimePlayed ?? false {
                    baseScore += " (a.p.)"
        }
        
        // Ajout des tirs au but si existants (ex: " (4-3 tab)")
        if let hp = homePenalties, let ap = awayPenalties {
            return "\(baseScore) (\(hp)-\(ap) tab)"
        }
        
        return baseScore
    }
}
