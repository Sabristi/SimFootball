//
//  Club.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 26/11/2025.
//
import Foundation

struct ClubIdentity: Codable, Hashable {
    let primaryColor: String
    let secondaryColor: String
    let nickname: String?
    let style: String
    
    init(primaryColor: String = "000000", secondaryColor: String = "FFFFFF", nickname: String? = nil, style: String = "Balanced") {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.nickname = nickname
        self.style = style
    }
}

struct ClubFinances: Codable, Hashable {
    var balance: Int
    var transferBudget: Int
    var wageBudget: Int
    
    init(balance: Int = 0, transferBudget: Int = 0, wageBudget: Int = 0) {
        self.balance = balance
        self.transferBudget = transferBudget
        self.wageBudget = wageBudget
    }
}

struct Club: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let acronym: String? // Nouvel attribut
    let foundedYear: Int
    let countryId: String
    let cityId: String?
    let stadiumId: String?
    let reputation: Int
    var leagueId: String
    let identity: ClubIdentity
    var finances: ClubFinances
    let rivalClubIds: [String]
    var kits: [Kit]
        
    // Helper pour récupérer un maillot spécifique
    func getKit(_ type: KitType) -> Kit? {
        return kits.first(where: { $0.type == type })
    }
    
    // Helper pour avoir une couleur principale (pour l'UI générique)
    var primaryColorHex: String {
        return getKit(.home)?.jerseyColors.first ?? "#FFFFFF"
    }
    
    var logoAssetName: String { return id }
    
    init(id: String,
         name: String,
         shortName: String,
         acronym: String? = nil,
         foundedYear: Int,
         countryId: String,
         cityId: String? = nil,
         stadiumId: String? = nil,
         leagueId: String,
         reputation: Int = 5000,
         kits: [Kit] = [],
         identity: ClubIdentity = ClubIdentity(),
         finances: ClubFinances = ClubFinances(),
         rivalClubIds: [String] = []) {
        
        self.id = id
        self.name = name
        self.shortName = shortName
        self.acronym = acronym // <-- Assurez-vous que cette ligne est bien là
        self.foundedYear = foundedYear
        self.countryId = countryId
        self.leagueId = leagueId
        self.cityId = cityId
        self.kits = kits
        self.stadiumId = stadiumId
        self.reputation = reputation
        self.identity = identity
        self.finances = finances
        self.rivalClubIds = rivalClubIds
    }
}
