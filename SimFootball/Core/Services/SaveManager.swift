//
//  SaveManager.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 23/11/2025.
//

import Foundation

class SaveManager {
    // Singleton : une seule instance pour toute l'app
    static let shared = SaveManager()
    
    private let fileManager = FileManager.default
    
    // Nom des fichiers : "save_1.json", "save_2.json"...
    private func getFileURL(slotId: Int) -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory.appendingPathComponent("save_\(slotId).json")
    }
    
    // MARK: - SAUVEGARDER (DB -> Fichier)
    func save(gameState: GameState, slotId: Int) -> Bool {
        guard let url = getFileURL(slotId: slotId) else { return false }
        
        do {
            // 1. On crée une copie mutable du GameState pour y injecter les données actuelles
            var stateToSave = gameState
            
            // 2. SNAPSHOT : On capture l'état actuel de la base de données
            print("💾 Snapshot des données dynamiques...")
            stateToSave.savedCompetitionSeasons = GameDatabase.shared.competitionSeasons
            stateToSave.savedMatches = GameDatabase.shared.matches
            stateToSave.savedMatchDays = GameDatabase.shared.matchDays
            stateToSave.savedLeagueTables = GameDatabase.shared.leagueTables
            stateToSave.savedCalendarEvents = GameDatabase.shared.calendarEvents
            
            // ✅ CORRECTION : On sauvegarde aussi l'historique !
            if let currentSave = GameDatabase.shared.currentSave {
                stateToSave.competitionHistory = currentSave.competitionHistory
            }
            
            // 3. On encode et on écrit sur le disque
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601 // Format de date robuste
            let data = try encoder.encode(stateToSave)
            try data.write(to: url)
            
            print("💾 Succès : Partie sauvegardée dans slot \(slotId)")
            return true
        } catch {
            print("❌ Erreur de sauvegarde : \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - CHARGER (Fichier -> DB)
    func load(slotId: Int) -> GameState? {
        guard let url = getFileURL(slotId: slotId),
              fileManager.fileExists(atPath: url.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // Format de date robuste
            let loadedState = try decoder.decode(GameState.self, from: data)
            
            // 4. RESTAURATION : On réinjecte les données sauvegardées dans la DB
            print("📂 Restauration des données dynamiques...")
            
            GameDatabase.shared.competitionSeasons = loadedState.savedCompetitionSeasons
            GameDatabase.shared.matches = loadedState.savedMatches
            GameDatabase.shared.matchDays = loadedState.savedMatchDays
            GameDatabase.shared.leagueTables = loadedState.savedLeagueTables
            GameDatabase.shared.calendarEvents = loadedState.savedCalendarEvents
            
            // ✅ CORRECTION MAJEURE : On reconstruit 'currentSave' pour que l'UI fonctionne
            var restoredSave = SaveData()
            //restoredSave.id = loadedState.id // Si GameState a un ID
            restoredSave.savedMatches = loadedState.savedMatches
            restoredSave.savedMatchDays = loadedState.savedMatchDays
            restoredSave.savedLeagueTables = loadedState.savedLeagueTables
            restoredSave.savedCalendarEvents = loadedState.savedCalendarEvents
            restoredSave.savedCompetitionSeasons = loadedState.savedCompetitionSeasons
            
            // On restaure l'historique
            restoredSave.competitionHistory = loadedState.competitionHistory
            
            // On injecte le tout dans GameDatabase
            GameDatabase.shared.currentSave = restoredSave
            
            print("✅ Historique restauré : \(loadedState.competitionHistory.count) entrées.")
            
            return loadedState
        } catch {
            print("❌ Erreur de chargement slot \(slotId) : \(error.localizedDescription)")
            return nil
        }
    }
    
    // VÉRIFIER SI UN SLOT EXISTE
    func exists(slotId: Int) -> Bool {
        guard let url = getFileURL(slotId: slotId) else { return false }
        return fileManager.fileExists(atPath: url.path)
    }
    
    // SUPPRIMER UNE SAUVEGARDE
    func deleteSave(slotId: Int) {
        guard let url = getFileURL(slotId: slotId) else { return }
        
        do {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
                print("🗑️ Slot \(slotId) supprimé avec succès.")
            }
        } catch {
            print("❌ Erreur lors de la suppression du slot \(slotId) : \(error.localizedDescription)")
        }
    }
}
