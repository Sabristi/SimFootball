//
//  Club.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 26/11/2025.
//
import Foundation

// 1. Identité du Club (Style, Couleurs, Culture)
struct ClubIdentity: Codable, Hashable {
    let primaryColor: String // Code Hex "FF0000"
    let secondaryColor: String // Code Hex "FFFFFF"
    let nickname: String? // "Les Aigles Verts"
    let style: String // "Possession", "Counter-Attack"... (Plus tard un Enum)
    
    // Initialiseur par défaut
    init(primaryColor: String = "000000",
         secondaryColor: String = "FFFFFF",
         nickname: String? = nil,
         style: String = "Balanced") {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.nickname = nickname
        self.style = style
    }
}

// 2. Finances du Club (Minimal pour le début)
struct ClubFinances: Codable, Hashable {
    var balance: Int // Solde en banque
    var transferBudget: Int // Budget transferts
    var wageBudget: Int // Budget salarial (hebdomadaire ou mensuel)
    
    init(balance: Int = 0, transferBudget: Int = 0, wageBudget: Int = 0) {
        self.balance = balance
        self.transferBudget = transferBudget
        self.wageBudget = wageBudget
    }
}

// 3. L'Entité Club Principale
struct Club: Identifiable, Codable, Hashable {
    let id: String // Ex: "CLUB-RCA"
    let name: String // "Raja Club Athletic"
    let shortName: String // "Raja CA"
    let foundedYear: Int // 1949
    
    // Relations (Clés étrangères)
    let countryId: String // Obligatoire
    let cityId: String? // Optionnel (si ville pas encore créée)
    let stadiumId: String? // Optionnel (si pas de stade assigné)
    
    // Stats
    let reputation: Int // 0 à 10000 (Standard FM)
    
    // Sous-structures
    let identity: ClubIdentity
    var finances: ClubFinances
    
    // Rivaux (Liste d'IDs de clubs)
    let rivalClubIds: [String]
    
    // Initialiseur complet
    init(id: String,
         name: String,
         shortName: String,
         foundedYear: Int,
         countryId: String,
         cityId: String? = nil,
         stadiumId: String? = nil,
         reputation: Int = 5000,
         identity: ClubIdentity = ClubIdentity(),
         finances: ClubFinances = ClubFinances(),
         rivalClubIds: [String] = []) {
        
        self.id = id
        self.name = name
        self.shortName = shortName
        self.foundedYear = foundedYear
        self.countryId = countryId
        self.cityId = cityId
        self.stadiumId = stadiumId
        self.reputation = reputation
        self.identity = identity
        self.finances = finances
        self.rivalClubIds = rivalClubIds
    }
}
