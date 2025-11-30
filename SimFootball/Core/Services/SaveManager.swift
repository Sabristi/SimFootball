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
    
    // SAUVEGARDER
    func save(gameState: GameState, slotId: Int) -> Bool {
        guard let url = getFileURL(slotId: slotId) else { return false }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // Pour pouvoir lire le JSON si on l'ouvre à la main
            let data = try encoder.encode(gameState)
            try data.write(to: url)
            print("💾 Succès : Partie sauvegardée dans slot \(slotId) à \(url.path)")
            return true
        } catch {
            print("❌ Erreur de sauvegarde : \(error.localizedDescription)")
            return false
        }
    }
    
    // CHARGER
    func load(slotId: Int) -> GameState? {
        guard let url = getFileURL(slotId: slotId),
              fileManager.fileExists(atPath: url.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let gameState = try decoder.decode(GameState.self, from: data)
            return gameState
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
