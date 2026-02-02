import Foundation

// MARK: - Enums pour la richesse et le développement
enum DevelopmentState: String, Codable, Hashable {
    case developed = "Developed"
    case developing = "Developing"
    case thirdWorld = "Third World"
}

enum GameImportance: String, Codable, Hashable {
    case veryImportant = "Very Important"
    case important = "Important"
    case medium = "Medium"
    case low = "Low"
    case veryLow = "Very Low"
}

// MARK: - Struct
struct Country: Identifiable, Codable, Hashable {
    // --- Identité de base ---
    let id: String
    let name: String
    let fifaCode: String
    let flagEmoji: String
    let continent: Continent
    let region: String?
    let confederationId: String?
    let isPlayable: Bool
    
    // --- Nouveaux Attributs "Football Manager" ---
    
    // 1. GÉNÉRATION DE JOUEURS (0-200 ou 0-20)
    /// La qualité moyenne des jeunes joueurs générés. (ex: Brésil = 180, Saint-Marin = 10)
    let youthRating: Int
    
    // 2. ÉCONOMIE & DÉVELOPPEMENT
    /// Le niveau de développement du pays, affecte les infrastructures et les budgets.
    let developmentState: DevelopmentState
    /// Facteur économique (0-20). Influence les salaires, les prix des billets et la valeur des clubs.
    let economicFactor: Int
    
    // 3. CULTURE FOOTBALL
    /// L'importance du football dans le pays. Influence l'affluence et la motivation des jeunes.
    let gameImportance: GameImportance
    
    // 4. NATURALISATION
    /// Nombre d'années nécessaires pour obtenir la nationalité (pour les joueurs étrangers).
    let yearsToGainNationality: Int
    
    // 5. CLASSEMENT FIFA (Dynamique ou statique pour le tri)
    var fifaRanking: Int?
    
    // Initialiseur mis à jour avec valeurs par défaut pour la rétrocompatibilité
    init(
        id: String,
        name: String,
        fifaCode: String? = nil,
        flagEmoji: String,
        continent: Continent,
        confederationId: String? = nil,
        region: String? = nil,

        isPlayable: Bool = true,
        // Nouveaux paramètres avec valeurs par défaut
        youthRating: Int = 50,
        developmentState: DevelopmentState = .developing,
        economicFactor: Int = 10,
        gameImportance: GameImportance = .medium,
        yearsToGainNationality: Int = 5
    ) {
        self.id = id.uppercased()
        self.name = name
        self.fifaCode = (fifaCode ?? id).uppercased()
        self.flagEmoji = flagEmoji
        self.continent = continent
        self.confederationId = confederationId
        self.region = region
        self.isPlayable = isPlayable
        
        self.youthRating = youthRating
        self.developmentState = developmentState
        self.economicFactor = economicFactor
        self.gameImportance = gameImportance
        self.yearsToGainNationality = yearsToGainNationality
    }
}
