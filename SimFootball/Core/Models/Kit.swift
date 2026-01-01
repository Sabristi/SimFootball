//
//  Kit.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 14/12/2025.
//

import Foundation
import SwiftUI

// 1. Type de Maillot
enum KitType: String, Codable, CaseIterable {
    case home = "Home"      // Domicile
    case away = "Away"      // Extérieur
    case third = "Third"    // Third (Optionnel)
    case goalkeeper = "GK"  // Gardien (Bonus pour plus tard)
}

// 2. Style de Maillot (Pour le dessin futur)
enum KitPattern: String, Codable, CaseIterable {
    // BASIQUES
    case solid = "Solid"                        // classic.png
    case classic = "Classic"                        // classic.png
    case classicBicolor = "ClassicBicolor"          // classic_bicolor.png (Manches diff)
    
    // BANDES HORIZONTALES
    case horizontalBand = "HorizontalBand"          // bande_horizontal.png
    case horizontalBandLarge = "HorizontalBandLarge"// bande_horizontal_large.png
    case horizontalBicolor = "HorizontalBicolor"    // bande_horizontal_bicolor.png
    case hoops = "Hoops"                            // rayures_horizontales.png
    
    // BANDES VERTICALES & RAYURES
    case verticalStripes = "VerticalStripes"        // rayures_classic.png
    case thinStripes = "ThinStripes"                // rayures_fines_verticales.png
    case tricolor = "Tricolor"                      // rayures_tricolor.png
    case centerStripe = "CenterStripe"              // classic_bande.png
    case centerStripe2 = "CenterStripe2"            // classic_bande_2.png
    case sidebar = "Sidebar"                        // bande_lateral_vertical_bicolor.png
    
    // ÉPAULES
    case shoulders = "Shoulders"                    // epaules.png
    case shouldersShort = "ShouldersShort"          // epaules_courtes.png
    case shouldersLarge = "ShouldersLarge"          // epaules_larges.png
    
    // FORMES GÉOMÉTRIQUES
    case half = "Half"                              // moitie_bicolor.png
    case diagonalHalf = "DiagonalHalf"              // oblique_bicolor.png
    case sash = "Sash"                              // diagonale_river.png
    case checkered = "Checkered"                    // croatia.png
    
    // STYLE HEATCHER
    case heatcher = "Heatcher"                      // heatcher.png
    case heatcherModern = "HeatcherModern"          // heatcher_moderne.png
    case heatcherOutline = "HeatcherOutline"        // heatcher_contour.png
    
    // Nom affiché dans l'interface d'édition
    var displayName: String {
        switch self {
        case .solid: return "Solide"
        case .classic: return "Classique"
        case .classicBicolor: return "Manches Contrastées"
        case .horizontalBand: return "Bande Horizontale"
        case .horizontalBandLarge: return "Bande H. Large"
        case .horizontalBicolor: return "Bande H. Bicolore"
        case .hoops: return "Rayures Horizontales"
        case .verticalStripes: return "Rayures Verticales"
        case .thinStripes: return "Rayures Fines"
        case .tricolor: return "Tricolore"
        case .centerStripe: return "Bande Centrale"
        case .centerStripe2: return "Bande Centrale V2"
        case .sidebar: return "Bande Latérale"
        case .shoulders: return "Épaules"
        case .shouldersShort: return "Épaules Courtes"
        case .shouldersLarge: return "Épaules Larges"
        case .half: return "Bicolore Vertical"
        case .diagonalHalf: return "Bicolore Oblique"
        case .sash: return "Diagonale"
        case .checkered: return "Damier"
        case .heatcher: return "Heatcher"
        case .heatcherModern: return "Heatcher Moderne"
        case .heatcherOutline: return "Heatcher Contour"
        }
    }
}

// 3. La Structure Kit
struct Kit: Identifiable, Codable, Hashable {
    var id: String { type.rawValue }
    
    let type: KitType
    var pattern: KitPattern
    
    // --- 1. TISSU & MOTIFS ---
    // Index 0 : Couleur de fond (Gris moyen dans le template)
    // Index 1 : Motif 1 (Blanc/Gris clair dans le template) - Optionnel
    // Index 2 : Motif 2 (Si existe) - Optionnel
    var jerseyColors: [String]
    
    // --- 2. DÉTAILS ---
    var collarColor: String  // Remplace le ROSE
    var sponsorColor: String // Remplace le VERT
    var logoColor: String    // Remplace le JAUNE
    
    // --- 3. BAS ---
    var shortsColor: String  // Remplace le Gris Foncé
    var socksColor: String   // Remplace le Gris Bas
    
    // Initialiseur complet
    init(type: KitType,
         pattern: KitPattern = .solid,
         jerseyColors: [String],
         collarColor: String = "#FFFFFF", // Blanc par défaut
         sponsorColor: String = "#FFFFFF",
         logoColor: String = "#FFD700",   // Or par défaut
         shortsColor: String,
         socksColor: String) {
        
        self.type = type
        self.pattern = pattern
        self.jerseyColors = jerseyColors
        self.collarColor = collarColor
        self.sponsorColor = sponsorColor
        self.logoColor = logoColor
        self.shortsColor = shortsColor
        self.socksColor = socksColor
    }
    
    
    func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(pattern, forKey: .pattern)
            try container.encode(jerseyColors, forKey: .jerseyColors)
            try container.encode(shortsColor, forKey: .shortsColor)
            try container.encode(socksColor, forKey: .socksColor)
            
            // VÉRIFIEZ QUE CES 3 LIGNES SONT BIEN LÀ :
            try container.encode(collarColor, forKey: .collarColor)
            try container.encode(sponsorColor, forKey: .sponsorColor)
            try container.encode(logoColor, forKey: .logoColor)
    }
    
    enum CodingKeys: String, CodingKey {
            case type, pattern, jerseyColors, shortsColor, socksColor
            case collarColor, sponsorColor, logoColor // Les nouvelles clés
        }

    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Champs obligatoires (ceux présents depuis le début)
            type = try container.decode(KitType.self, forKey: .type)
            pattern = try container.decode(KitPattern.self, forKey: .pattern)
            jerseyColors = try container.decode([String].self, forKey: .jerseyColors)
            shortsColor = try container.decode(String.self, forKey: .shortsColor)
            socksColor = try container.decode(String.self, forKey: .socksColor)
            
            // Champs optionnels avec valeurs par défaut (ESSENTIEL pour ne pas planter)
            collarColor = try container.decodeIfPresent(String.self, forKey: .collarColor) ?? "#FF00FF"
            sponsorColor = try container.decodeIfPresent(String.self, forKey: .sponsorColor) ?? "#00FF00"
            logoColor = try container.decodeIfPresent(String.self, forKey: .logoColor) ?? "#FFFF00"
    }
}

