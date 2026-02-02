//
//  NationalTeam.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import Foundation

// MARK: - Types d'Équipes Nationales
enum NationalTeamType: String, Codable, Hashable {
    case senior = "A" // Équipe A
    case u23 = "U23"       // Olympique
    case u20 = "U20"
    case u17 = "U17"
}

// MARK: - Struct NationalTeam
struct NationalTeam: Identifiable, Codable, Hashable {
    
    // Identifiant unique (ex: "FRA_A", "FRA_U20")
    let id: String
    
    // ✅ Clé étrangère vers l'objet Country (Pas de redondance de nom/drapeau)
    let countryId: String
    
    // Le type (A, U21, etc.)
    let type: NationalTeamType
    
    // --- Attributs Sportifs ---
    
    /// Réputation sportive actuelle (peut différer de l'importance du pays)
    var reputation: Int // 0-10000
    
    /// Stade principal pour les matchs à domicile (ex: Stade de France)
    var stadiumId: String?
    
    // --- Staff & Effectif ---
    
    /// ID du Sélectionneur
    var managerId: String?
    
    /// ID du Capitaine actuel
    var captainId: String?
    
    // --- Initialiseur ---
    init(
        id: String? = nil,
        countryId: String,
        type: NationalTeamType = .senior,
        reputation: Int = 5000,
        stadiumId: String? = nil,
    ) {
        self.countryId = countryId.uppercased()
        self.type = type
        // Génération d'ID composite automatique si non fourni : "NT_FRA_SENIOR"
        self.id = id ?? "\(countryId.uppercased())_\(type.rawValue.uppercased())"
        
        self.reputation = reputation
        self.stadiumId = stadiumId
        self.managerId = nil
        self.captainId = nil
    }
}

// MARK: - Extensions pour l'affichage (Computed Properties)
// C'est ici qu'on fait le lien avec Country pour récupérer les infos sans les stocker
extension NationalTeam {
    
    // Récupération dynamique du Pays via la Base de Données
    var country: Country? {
        // Supposons que vous ayez accès à votre GameDatabase ici
        return GameDatabase.shared.countries.first(where: { $0.id == countryId })
    }
    
    // Nom affiché (ex: "France" ou "France U21")
    var displayName: String {
        guard let c = country else { return "Unknown Team" }
        
        switch type {
        case .senior:
            return c.name
        default:
            return "\(c.name) \(type.rawValue)"
        }
    }
    
    // Drapeau (récupéré du pays)
    var flagEmoji: String {
        return country?.flagEmoji ?? "🏳️"
    }
    
    // Code FIFA (récupéré du pays)
    var fifaCode: String {
        return country?.fifaCode ?? "UNK"
    }
}
