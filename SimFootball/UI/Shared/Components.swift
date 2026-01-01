//
//  Components.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 03/12/2025.
//

import SwiftUI

// --- GESTION MULTI-PLATEFORME (iOS vs macOS) ---
// Nécessaire pour la fonction imageExists
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// ------------------------------------------------------------------
// 1. FONCTION UTILITAIRE (Accessible partout)
// ------------------------------------------------------------------

/// Vérifie si une image existe dans le catalogue d'Assets
func imageExists(named name: String) -> Bool {
    #if os(macOS)
    return NSImage(named: name) != nil
    #else
    return UIImage(named: name) != nil
    #endif
}

// ------------------------------------------------------------------
// 2. COMPOSANTS VISUELS PARTAGÉS
// ------------------------------------------------------------------

/// Affiche le logo d'un club ou une image par défaut
struct ClubLogoView: View {
    let clubId: String
    let size: CGFloat
    
    var body: some View {
        if imageExists(named: clubId) {
            Image(clubId)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            // Fallback : Image par défaut
            // Assurez-vous d'avoir une image nommée "default" dans Assets.xcassets
            Image("default")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .background(
                    Circle().fill(Color.white.opacity(0.05)).frame(width: size, height: size)
                )
        }
    }
}

/// Affiche le logo d'une compétition ou une initiale
struct CompetitionLogoView: View {
    let competitionId: String
    let size: CGFloat
    
    var body: some View {
        // 1. Essai avec l'image (ex: "COMP-MAR-BP1")
        if imageExists(named: competitionId) {
            Image(competitionId)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            // 2. Fallback : Cercle avec initiale (nécessite l'accès à GameDatabase)
            // On récupère le shortName de la compétition
            let shortName = GameDatabase.shared.competitions.first { $0.id == competitionId }?.shortName ?? "C"
            
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: size, height: size)
                .overlay(
                    Text(shortName.prefix(1))
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
}
