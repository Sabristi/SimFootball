//
//  Country.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 23/11/2025.
//

import Foundation

// 1. Type de pays (Pour distinguer les nations FIFA, les non-affiliés, etc.)
enum CountryType: String, Codable {
    case standard = "Standard"         // Nation classique (France, Maroc...)
    case federation = "Fédération"     // Si besoin de gérer des cas spéciaux
    case historical = "Historique"     // Ex: URSS, Yougoslavie (pour l'historique)
}

// 2. L'Entité Country Complète
struct Country: Identifiable, Codable, Hashable {
    let id: String
    let fifaCode: String
    let name: String
    let flagEmoji: String
    
    let continent: Continent
    let region: String?
    let confederationId: String? // <--- C'ÉTAIT UUID?, C'EST MAINTENANT STRING?
    
    let type: CountryType
    let isPlayable: Bool
    
    init(id: String,
         fifaCode: String? = nil,
         name: String,
         flagEmoji: String,
         continent: Continent,
         confederationId: String? = nil, // <--- ICI AUSSI
         region: String? = nil,
         type: CountryType = .standard,
         isPlayable: Bool = true) {
        
        self.id = id.uppercased()
        self.fifaCode = (fifaCode ?? id).uppercased()
        self.name = name
        self.flagEmoji = flagEmoji
        self.continent = continent
        self.confederationId = confederationId
        self.region = region
        self.type = type
        self.isPlayable = isPlayable
    }
}
