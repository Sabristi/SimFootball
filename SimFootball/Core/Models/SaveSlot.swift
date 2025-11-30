//
//  SaveSlot.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 23/11/2025.
//

import Foundation

struct SaveSlot: Identifiable {
    let id: Int
    let isEmpty: Bool
    
    // Données si le slot est occupé
    var managerName: String?
    var teamName: String?
    var seasonYear: String?
    var lastPlayed: Date?
    
    // Fonction helper pour créer un slot vide
    static func empty(id: Int) -> SaveSlot {
        SaveSlot(id: id, isEmpty: true)
    }
    
    // Fonction helper pour créer un slot occupé (pour tester le design)
    static func mock(id: Int, team: String, year: String) -> SaveSlot {
        SaveSlot(
            id: id,
            isEmpty: false,
            managerName: "Coach Doe",
            teamName: team,
            seasonYear: year,
            lastPlayed: Date()
        )
    }
}
