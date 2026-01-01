//
//  GameManager.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//
import Foundation
import SwiftUI
import Combine

// C'est le cerveau du temps et de la simulation
class GameManager: ObservableObject {
    
    // Singleton : Accessible partout via GameManager.shared
    static let shared = GameManager()
    
    // --- ÉTAT DU JEU ---
    // La date est maintenant ici, plus dans la Vue
    @Published var currentDate: Date
    
    // Pour déclencher des popups dans l'interface
    @Published var showNewSeasonPopup: Bool = false
    
    // Initialisation
    private init() {
        // On démarre par exemple le 1er Août 2025
        // (Dans le futur, on chargera ça depuis la sauvegarde)
        var components = DateComponents()
        components.year = 2025
        components.month = 8
        components.day = 1
        self.currentDate = Calendar.current.date(from: components) ?? Date()
        
        print("✅ [GameManager] Initialisé au : \(currentDate.formatted(date: .numeric, time: .omitted))")
    }
    
    // --- MÉTHODE PRINCIPALE ---
    // C'est la seule fonction que la Vue devra appeler quand on clique sur "CONTINUE"
    func advanceTime() {
        
        // 1. On avance d'un jour
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else { return }
        
        // Mise à jour de la date (l'UI se rafraîchira automatiquement)
        self.currentDate = nextDay
        print("\n📆 [GameManager] Nouveau jour : \(currentDate.formatted(date: .numeric, time: .omitted))")
        
        // 2. On vérifie et simule les matchs du jour
        playDailyMatches()
        
        // 3. On vérifie si c'est la fin de saison
        checkSeasonTransition()
        
        // TODO: Ajouter ici la sauvegarde automatique si besoin
        // saveGame()
    }
    
    // --- LOGIQUE INTERNE ---
    
    private func playDailyMatches() {
        // A. On récupère les matchs prévus à cette date via GameDatabase
        let todaysMatches = GameDatabase.shared.getMatches(forDate: currentDate)
        
        // B. On ne garde que ceux NON joués
        let matchesToPlay = todaysMatches.filter { $0.status != .played }
        
        if !matchesToPlay.isEmpty {
            print("⚽️ Simulation de \(matchesToPlay.count) matchs...")
            
            // C. On lance le Moteur de Simulation (votre SimulationEngine)
            _ = SimulationEngine.shared.simulateMatches(matchesToPlay)
            
            // SimulationEngine met à jour GameDatabase, donc l'UI suivra.
        } else {
            print("💤 Aucun match aujourd'hui.")
        }
    }
    
    private func checkSeasonTransition() {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        
        // Le 9 Juillet est notre date de bascule
        if month == 7 && day == 9 {
            print("⚠️ [GameManager] BASCULE DE SAISON !")
            
            let currentYear = calendar.component(.year, from: currentDate)
            
            // On archive la saison précédente (N-1)
            SeasonTransitionManager.shared.processSeasonTransition(currentYear: currentYear - 1)
            
            // On demande à l'UI d'afficher la popup
            self.showNewSeasonPopup = true
        }
    }
    
    // Fonction pour charger une date spécifique (depuis une sauvegarde)
    func loadDate(_ date: Date) {
        self.currentDate = date
    }
}
