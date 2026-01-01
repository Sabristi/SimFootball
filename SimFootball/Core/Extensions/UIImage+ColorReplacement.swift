//
//  UIImage+ColorReplacement.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// Nécessite PlatformUtils.swift pour PlatformImage/PlatformColor

extension PlatformImage {
    
    func colorized(
        base: String,       // #CCCCCC (Gris Clair)
        pattern1: String,   // #00FFFF (Cyan)
        pattern2: String,   // #FF0000 (Rouge)
        collar: String,     // #FF00FF (Magenta)
        sponsor: String,    // #00FF00 (Vert)
        logo: String,       // #FFFF00 (Jaune)
        shorts: String,     // #4D4D4D (Gris Foncé)
        socks: String       // #FF6600 (Orange)
    ) -> PlatformImage? {
        
        // 1. Conversion Hex -> CGColor
        guard let cBase = parseHexToCGColor(base),
              let cPat1 = parseHexToCGColor(pattern1),
              let cPat2 = parseHexToCGColor(pattern2),
              let cCollar = parseHexToCGColor(collar),
              let cSponsor = parseHexToCGColor(sponsor),
              let cLogo = parseHexToCGColor(logo),
              let cShorts = parseHexToCGColor(shorts),
              let cSocks = parseHexToCGColor(socks) else { return nil }
        
        // 2. Setup Contexte
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: &rawData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerPixel * width,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 3. PIXEL MAPPING
        for i in 0..<(width * height) {
            let offset = i * bytesPerPixel
            let r = rawData[offset]
            let g = rawData[offset + 1]
            let b = rawData[offset + 2]
            let a = rawData[offset + 3]
            
            if a > 0 { // Ignorer la transparence
                
                // --- A. LES COULEURS "CLÉS" (Flashy) ---
                
                // 1. CYAN -> MOTIF 1 (#00FFFF)
                // R faible, G et B forts
                if r < 100 && g > 200 && b > 200 {
                    replacePixel(at: offset, in: &rawData, with: cPat1)
                }
                
                // 2. ROUGE -> MOTIF 2 (#FF0000)
                // R fort, G et B faibles
                else if r > 200 && g < 100 && b < 100 {
                    replacePixel(at: offset, in: &rawData, with: cPat2)
                }
                
                // 3. MAGENTA -> COL (#FF00FF)
                // R et B forts, G faible
                else if r > 200 && b > 200 && g < 100 {
                    replacePixel(at: offset, in: &rawData, with: cCollar)
                }
                
                // 4. VERT -> SPONSOR (#00FF00)
                // G fort, R et B faibles
                else if g > 200 && r < 100 && b < 100 {
                    replacePixel(at: offset, in: &rawData, with: cSponsor)
                }
                
                // 5. JAUNE -> CREST/LOGO (#FFFF00)
                // R et G forts, B faible
                else if r > 200 && g > 200 && b < 100 {
                    replacePixel(at: offset, in: &rawData, with: cLogo)
                }
                
                // 6. ORANGE -> CHAUSSETTES (#FF6600)
                // R fort, G moyen (~100), B faible
                else if r > 200 && g > 80 && g < 150 && b < 50 {
                    replacePixel(at: offset, in: &rawData, with: cSocks)
                }
                
                // --- B. LES NIVEAUX DE GRIS ---
                
                // On vérifie que R, G et B sont proches (caractéristique du gris)
                else if abs(Int(r) - Int(g)) < 25 && abs(Int(r) - Int(b)) < 25 {
                    
                    let val = Int(r)
                    
                    // 7. GRIS FONCÉ -> SHORT (#4D4D4D = 77)
                    // Plage cible : 60 à 100
                    if val > 60 && val < 100 {
                        replacePixel(at: offset, in: &rawData, with: cShorts)
                    }
                    
                    // 8. GRIS CLAIR -> CORPS MAILLOT (#CCCCCC = 204)
                    // Plage cible : 180 à 230
                    // Note : Comme le Cyan et le Blanc ne se mélangent plus, c'est très sûr.
                    else if val > 180 && val < 230 {
                        replacePixel(at: offset, in: &rawData, with: cBase)
                    }
                }
            }
        }
        
        guard let newCGImage = context.makeImage() else { return nil }
        return PlatformImage(cgImage: newCGImage, size: self.size)
    }
    
    private func replacePixel(at offset: Int, in data: inout [UInt8], with color: CGColor) {
        guard let components = color.components, components.count >= 3 else { return }
        data[offset]     = UInt8(components[0] * 255)
        data[offset + 1] = UInt8(components[1] * 255)
        data[offset + 2] = UInt8(components[2] * 255)
    }
    
    private func parseHexToCGColor(_ hex: String) -> CGColor? {
        if hex.isEmpty { return PlatformColor.black.cgColor }
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        return PlatformColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1.0).cgColor
    }
}
