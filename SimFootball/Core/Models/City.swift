//
//  City.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 25/11/2025.
//

import Foundation

// 1. Rang de la ville (Taille/Importance)
enum CityRank: String, Codable {
    case globalCity = "Global City"     // Londres, Paris, NY
    case metropolis = "Metropolis"      // Lyon, Manchester, Casablanca
    case majorCity = "Major City"       // Bordeaux, Seville
    case town = "Town"                  // Petite ville
    case village = "Village"
}

// 2. Type de capitale politique
enum PoliticalCapitalType: String, Codable {
    case none = "None"
    case standard = "Standard"          // Capitale unique (ex: Paris)
    case executive = "Executive"        // Si capitale divisée
    case legislative = "Legislative"
    case judicial = "Judicial"
}

// 3. L'Entité Ville
struct City: Identifiable, Codable, Hashable {
    let id: String                      // UUID String (ex: "CITY-001")
    let name: String                    // "Paris"
    let countryId: String               // Lookup vers Country.id (ex: "FRA")
    
    let population: Int                 // 2100000
    let rank: CityRank
    let capitalType: PoliticalCapitalType
    let recordTypeId: String            // "Standard", "Capital" (Architecture Salesforce-like)
    
    // Initialiseur
    init(id: String = UUID().uuidString,
         name: String,
         countryId: String,
         population: Int,
         rank: CityRank,
         capitalType: PoliticalCapitalType = .none,
         recordTypeId: String = "Standard") {
        
        self.id = id
        self.name = name
        self.countryId = countryId
        self.population = population
        self.rank = rank
        self.capitalType = capitalType
        self.recordTypeId = recordTypeId
    }
}
