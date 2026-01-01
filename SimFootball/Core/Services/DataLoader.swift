//
//  DataLoader.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 23/11/2025.
//

import Foundation

class DataLoader {
    
    static func load<T: Decodable>(_ filename: String) -> T {
        let data: Data
        
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
            fatalError("❌ Fichier introuvable : \(filename)")
        }
        
        do {
            data = try Data(contentsOf: file)
        } catch {
            fatalError("❌ Impossible de lire le fichier : \(filename)\n\(error)")
        }
        
        do {
            let decoder = JSONDecoder()
            // Cette option permet de décoder les dates si besoin (pas utilisé ici mais utile plus tard)
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            print(context)
            fatalError("❌ JSON Corrompu dans \(filename) : \(context.debugDescription)")
        } catch let DecodingError.keyNotFound(key, context) {
            print("Context:", context)
            fatalError("❌ Clé manquante dans \(filename) : '\(key.stringValue)' n'a pas été trouvée.")
        } catch let DecodingError.valueNotFound(value, context) {
            print("Context:", context)
            fatalError("❌ Valeur manquante dans \(filename) : Type '\(value)' attendu mais non trouvé : \(context.debugDescription)")
        } catch let DecodingError.typeMismatch(type, context) {
            print("Context:", context)
            fatalError("❌ Erreur de Type dans \(filename) : Type '\(type)' attendu, mais le JSON contient autre chose à : \(context.codingPath)")
        } catch {
            fatalError("❌ Erreur inconnue : \(error)")
        }
    }
}
