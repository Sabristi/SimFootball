//
//  Country.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 23/11/2025.
//

import Foundation

struct Country: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let fifaCode: String
    let flagEmoji: String
    
    // 🛡️ ON FORCE LE STRING pour éviter les erreurs de décodage Enum (majuscules/minuscules)
    let continent: String
    let type: String?
    
    let region: String?
    let confederationId: String?
    let isPlayable: Bool
    
    // Initialiseur standard
    init(id: String, name: String, fifaCode: String? = nil, flagEmoji: String, continent: String, confederationId: String? = nil, region: String? = nil, type: String? = "Standard", isPlayable: Bool = true) {
        self.id = id.uppercased()
        self.name = name
        self.fifaCode = (fifaCode ?? id).uppercased()
        self.flagEmoji = flagEmoji
        self.continent = continent
        self.confederationId = confederationId
        self.region = region
        self.type = type
        self.isPlayable = isPlayable
    }
    
    // 🛡️ INIT DE DÉCODAGE BLINDÉ
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Gestion des champs optionnels ou avec fallback
        fifaCode = (try? container.decode(String.self, forKey: .fifaCode)) ?? id
        flagEmoji = (try? container.decode(String.self, forKey: .flagEmoji)) ?? "🏳️"
        
        // Ici, on accepte n'importe quelle String pour le continent
        continent = (try? container.decode(String.self, forKey: .continent)) ?? "Unknown"
        
        region = try? container.decode(String.self, forKey: .region)
        confederationId = try? container.decode(String.self, forKey: .confederationId)
        type = try? container.decode(String.self, forKey: .type)
        
        isPlayable = (try? container.decode(Bool.self, forKey: .isPlayable)) ?? false
    }
}
