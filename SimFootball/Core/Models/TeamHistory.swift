//
//  TeamHistory.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 28/12/2025.
//

import Foundation

// MARK: - 1. Performance dans une Compétition
// Représente le résultat d'une équipe dans UNE compétition spécifique pour UNE saison
struct CompetitionPerformance: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    let competitionId: String   // Ex: "COMP-MAR-BP1" ou "COMP-CAF-CL"
    
    // Résultat
    let rankLabel: String       // Ex: "3rd", "Winner", "Semi-Finalist", "Group Stage"
    let preciseRank: Int?       // Ex: 3 (utile pour les graphiques d'évolution en championnat)
    let roundReachedId: String? // Ex: "R_SEMI", "R_FINAL" (pour les coupes)
    
    // Stats (Optionnel, pour le détail)
    var matchesPlayed: Int?
    var wins: Int?
    var draws: Int?
    var losses: Int?
    var points: Int?
    
    // Indicateurs Palmarès
    let isWinner: Bool          // True si trophée gagné
    let isPromoted: Bool        // True si montée
    let isRelegated: Bool       // True si descente
    let isContinentalQualified: Bool // True si qualifié pour l'Afrique/Europe
}

// MARK: - 2. Entrée Historique Saison (L'objet principal)
// Représente toute la saison d'une équipe
struct TeamSeasonHistory: Codable, Identifiable, Hashable {
    let id: String              // Ex: "H_RCA_2025_26"
    let teamId: String          // ID du Club ou du Pays
    let seasonId: String        // "S_2025_26"
    let yearLabel: String       // "2025/2026"
    
    // Liste des compétitions jouées cette saison-là
    var performances: [CompetitionPerformance]
    
    // Stats globales de la saison (Optionnel)
    var totalGoalsScored: Int
    var totalGoalsConceded: Int
    var topScorerName: String?
    var averageAttendance: Int?
    
    // Helper pour récupérer le trophée majeur s'il y en a un
    var majorTrophy: CompetitionPerformance? {
        performances.first { $0.isWinner }
    }
}

// MARK: - 3. Objet "Trophée" (Pour la Salle des Trophées)
// Une structure légère dérivée de l'historique pour l'affichage facile
struct TrophyItem: Identifiable, Hashable {
    let id = UUID()
    let competitionId: String
    let seasonLabel: String     // "2025/26"
    let dateWon: Date           // Pour trier chronologiquement
}
