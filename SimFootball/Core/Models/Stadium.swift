//
//  Stadium.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 25/11/2025.
//

import Foundation

// Type de surface de jeu
enum StadiumSurface: String, Codable {
    case grass = "Grass"         // Pelouse naturelle
    case hybrid = "Hybrid"       // Hybride (très courant en pro)
    case synthetic = "Synthetic" // Synthétique
    case clay = "Clay"           // Terre battue (rare en pro)
    case gravel = "Gravel"       // Stabilisé
}

struct Stadium: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    
    // Relations (Clés étrangères)
    let cityId: String      // Lookup City
    let countryId: String   // Lookup Country (Redondant mais optimise les requêtes "Stades par pays")
    
    // Caractéristiques techniques
    let capacity: Int
    let altitude: Int       // En mètres (Impacte la fatigue)
    let surface: StadiumSurface
    let yearBuilt: Int
    let hasRoof: Bool       // Toit (Impacte la météo)
    
    // Initialiseur
    init(id: String = UUID().uuidString,
         name: String,
         cityId: String,
         countryId: String,
         capacity: Int,
         altitude: Int = 0,
         surface: StadiumSurface = .grass,
         yearBuilt: Int,
         hasRoof: Bool = false) {
        
        self.id = id
        self.name = name
        self.cityId = cityId
        self.countryId = countryId
        self.capacity = capacity
        self.altitude = altitude
        self.surface = surface
        self.yearBuilt = yearBuilt
        self.hasRoof = hasRoof
    }
}
