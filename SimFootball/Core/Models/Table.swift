//
//  Table.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 29/11/2025.
//

import Foundation

/// Représente une ligne dans le classement (Une équipe)
struct LeagueTableEntry: Identifiable, Codable, Hashable {
    let id: String
    
    // Contexte
    var competitionId: String
    var seasonId: String
    var competitionSeasonId: String
    var stageId: String
    var tableId: String
    
    // Équipe & Alias
    var teamId: String
    let teamAlias: String
    
    // Classement dynamique
    var position: Int
    
    // Stats
    var points: Int
    var played: Int
    var won: Int
    var drawn: Int
    var lost: Int
    var goalsFor: Int
    var goalsAgainst: Int
    
    // Propriété calculée : On la garde calculée pour garantir qu'elle est toujours juste
    var goalDifference: Int {
        return goalsFor - goalsAgainst
    }
    
    // Forme récente
    var form: [String] = []
    
    // MARK: - INITIALISEUR ADAPTÉ
    // J'ai ajouté 'form' ici pour correspondre à votre appel.
    // J'ai retiré 'goalDifference' car c'est une formule automatique.
    init(id: String = UUID().uuidString,
         competitionId: String,
         seasonId: String,
         competitionSeasonId: String,
         stageId: String,
         tableId: String,
         teamId: String,
         teamAlias: String,
         position: Int,
         points: Int = 0,
         played: Int = 0,
         won: Int = 0,
         drawn: Int = 0,
         lost: Int = 0,
         goalsFor: Int = 0,
         goalsAgainst: Int = 0,
         form: [String] = []) { // ✅ AJOUTÉ : form est maintenant accepté
        
        self.id = id
        self.competitionId = competitionId
        self.seasonId = seasonId
        self.competitionSeasonId = competitionSeasonId
        self.stageId = stageId
        self.tableId = tableId
        self.teamId = teamId
        self.teamAlias = teamAlias
        self.position = position
        self.points = points
        self.played = played
        self.won = won
        self.drawn = drawn
        self.lost = lost
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.form = form // ✅ Assignation
    }
}
