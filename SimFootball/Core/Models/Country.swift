//
//  Country.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 23/11/2025.
//

import Foundation

enum CountryType: String, Codable, Hashable {
    case standard = "Standard"
    case historical = "Historical" // Exemple si tu en as d'autres
}

// MARK: - Struct
struct Country: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let fifaCode: String
    let flagEmoji: String
    
    // ✅ Retour aux Enums fortement typés
    let continent: Continent
    let type: CountryType?
    
    let region: String?
    let confederationId: String?
    let isPlayable: Bool
    
    // Initialiseur standard
    init(id: String, name: String, fifaCode: String? = nil, flagEmoji: String, continent: Continent, confederationId: String? = nil, region: String? = nil, type: CountryType? = .standard, isPlayable: Bool = true) {
        self.id = id.uppercased()
        self.name = name
        self.fifaCode = (fifaCode ?? id).uppercased()
        self.flagEmoji = flagEmoji
        self.continent = continent
        self.confederationId = confederationId
        self.region = region
        self.type = type
        self.isPlayable = isPlayable
    }
    
}
