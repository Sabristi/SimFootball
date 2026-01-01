//
//  ColorExtensions.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 28/11/2025.
//

import SwiftUI


extension Color {
    
    // --- 2. INITIALISEUR (Hex -> Color) ---
    // Permet de créer une couleur depuis une String JSON ex: "#FF0000"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // --- 3. CONVERSION (Color -> Hex) ---
    // Permet de sauvegarder la couleur du ColorPicker vers le JSON
    func toHex() -> String? {
        // Convertir le Color SwiftUI en couleur native (NSColor ou UIColor)
        let platformColor = PlatformColor(self)
        
        // Sur Mac, on force l'espace sRGB pour avoir les bons composants
        #if os(macOS)
        guard let cgColor = platformColor.usingColorSpace(.sRGB)?.cgColor else { return nil }
        #else
        let cgColor = platformColor.cgColor
        #endif
        
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// --- 4. HELPER BINDING (String Hex <-> Color Picker) ---
// Pont entre la String du modèle de données et le Color de la Vue
func binding(for hexColor: Binding<String>) -> Binding<Color> {
    return Binding<Color>(
        get: {
            Color(hex: hexColor.wrappedValue)
        },
        set: { newColor in
            if let hex = newColor.toHex() {
                hexColor.wrappedValue = hex
            }
        }
    )
}
