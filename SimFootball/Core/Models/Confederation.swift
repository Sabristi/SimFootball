//
//  Untitled.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 23/11/2025.
//

import Foundation

// 1. Énumération pour la portée (Scope)
enum ConfederationScope: String, Codable, CaseIterable {
    case global = "Mondial"         // Ex: FIFA
    case continental = "Continental" // Ex: UEFA, CAF
    case regional = "Regional"      // Ex: UNAF, WAFF
    case cultural = "Culturel"      // Ex: UAFA (Union Arabe)
    case other = "Autre"
}

// 2. Énumération pour les Continents (Utile pour le filtrage géographique)
enum Continent: String, Codable, CaseIterable {
    case africa = "Africa"
    case europe = "Europe"
    case asia = "Asia"
    case southAmerica = "South America"
    case northAmerica = "North America"
    case oceania = "Oceania"
    case world = "World" // Pour la FIFA
}

// 3. L'Entité Confederation
struct Confederation: Identifiable, Codable, Hashable {
    let id: String          // <--- C'ÉTAIT UUID, C'EST MAINTENANT STRING
    let name: String
    let shortName: String
    let scope: ConfederationScope
    let continent: Continent?
    let logoPath: String
    
    // Initialiseur mis à jour
    init(id: String, name: String, shortName: String, scope: ConfederationScope, continent: Continent?, logoPath: String? = nil) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.scope = scope
        self.continent = continent
        self.logoPath = logoPath ?? "logo_\(shortName.lowercased())"
    }
    
    // Helpers statiques mis à jour avec des Strings
    static let fifa = Confederation(id: "FIFA", name: "Fédération Internationale...", shortName: "FIFA", scope: .global, continent: .world)
    static let uefa = Confederation(id: "UEFA", name: "Union of European...", shortName: "UEFA", scope: .continental, continent: .europe)
    static let caf = Confederation(id: "CAF", name: "Confédération Africaine...", shortName: "CAF", scope: .continental, continent: .africa)
    static let conmebol = Confederation(id: "CONMEBOL", name: "Confederación Sudamericana...", shortName: "CONMEBOL", scope: .continental, continent: .southAmerica)
}
