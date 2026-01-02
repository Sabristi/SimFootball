import Foundation

// MARK: - 1. NAVIGATION DU JEU
/// Les différents onglets accessibles dans le menu latéral du jeu
enum GameTab: String, CaseIterable {
    case inbox = "Inbox"
    case home = "Home"
    case primaryCountry = "Primary Country"
    case world = "World"
    case squad = "Squad"
    case scouting = "Scouting"
    case settings = "Settings"
    
    // --- COMPÉTITIONS & CLUBS ---
    case league = "League"
    case club = "Club" // ✅ NOUVEAU CAS AJOUTÉ
    
    // --- JOUR DE MATCH ---
    case matchDay = "Match Day"
    
    var title: String {
        switch self {
        case .inbox: return "News & Inbox"
        case .home: return "Manager Home"
        case .primaryCountry: return "National Team"
        case .world: return "World Competitions"
        case .squad: return "Squad Management"
        case .scouting: return "Scouting Network"
        case .settings: return "Options"
        case .league: return "League Center"
        case .club: return "Club Center" // Titre pour l'onglet Club
        case .matchDay: return "Live Match Center" // Titre du Header
        }
    }
    
    var icon: String {
        switch self {
        case .inbox: return "envelope.fill"
        case .home: return "house.fill"
        case .primaryCountry: return "flag.fill"
        case .world: return "globe.europe.africa.fill"
        case .squad: return "person.3.fill"
        case .scouting: return "magnifyingglass"
        case .settings: return "gearshape.fill"
        case .league: return "trophy.fill"
        case .club: return "shield.fill" // Icône pour le Club
        case .matchDay: return "sportscourt.fill" // Icône du Header
        }
    }
}

// MARK: - 2. MODES DE JEU
/// Le rôle incarné par le joueur
enum GameMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case owner = "Owner Mode"
    case manager = "Manager Mode"
    case commissioner = "Commissioner Mode"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .owner: return "Manage finances, stadium, and hire staff."
        case .manager: return "Focus on tactics, training, and matches."
        case .commissioner: return "God mode. Control the entire world."
        }
    }
    
    var icon: String {
        switch self {
        case .owner: return "building.2.fill"
        case .manager: return "person.fill.checkmark"
        case .commissioner: return "globe.europe.africa.fill"
        }
    }
}

// MARK: - 3. ÉTAT DU JEU (GAMESTATE)
/// L'objet racine qui est sauvegardé dans le fichier JSON (Save slot)
struct GameState: Codable, Identifiable, Hashable {
    var id: UUID
    var saveSlotId: Int
    var saveName: String
    var worldId: UUID
    
    // --- GESTION DU TEMPS ---
    var currentDate: Date
    var currentSeasonId: String // ID de la saison en cours (ex: "S_2025_26")
    
    // --- PARAMÈTRES DE LA PARTIE ---
    var gameMode: GameMode
    var selectedCountries: [Country] // Pays jouables sélectionnés
    
    // --- PROGRESSION ---
    var readEventIds: Set<String> // IDs des messages (CalendarEvent) déjà lus par le joueur
    
    // --- MÉTADONNÉES ---
    var createdAt: Date
    var gameVersion: String
    
    // --- DONNÉES DYNAMIQUES SAUVEGARDÉES ---
    // Ces tableaux permettent de persister l'état de la base de données (matchs joués, classements, tirages...)
    var savedCompetitionSeasons: [CompetitionSeason] = []
    var savedMatches: [Match] = []
    var savedMatchDays: [MatchDay] = []
    var savedLeagueTables: [LeagueTableEntry] = []
    var savedCalendarEvents: [SeasonCalendarEvent] = []
    var competitionHistory: [CompetitionHistoryEntry] = []
    
    // ✅ AJOUT : Historique des équipes (Palmarès individuel)
    var savedTeamHistories: [TeamSeasonHistory] = []
    
    /// Crée une nouvelle partie vierge
    static func createNew(slotId: Int, mode: GameMode, countries: [Country]) -> GameState {
        // Date de départ fixe pour la saison 2025/2026
        let components = DateComponents(year: 2025, month: 7, day: 15)
        let startDate = Calendar.current.date(from: components) ?? Date()
        
        return GameState(
            id: UUID(),
            saveSlotId: slotId,
            saveName: "Save \(slotId)",
            worldId: UUID(),
            currentDate: startDate,
            currentSeasonId: "S_2025_26", // Valeur par défaut pour le début
            gameMode: mode,
            selectedCountries: countries,
            readEventIds: [], // Aucun message lu au début
            createdAt: Date(),
            gameVersion: "0.1.0",
            // Les tableaux dynamiques sont initialisés vides par défaut
            savedCompetitionSeasons: [],
            savedMatches: [],
            savedMatchDays: [],
            savedLeagueTables: [],
            savedCalendarEvents: [],
            competitionHistory: [],
            savedTeamHistories: [] // ✅ Initialisation vide
        )
    }
}
