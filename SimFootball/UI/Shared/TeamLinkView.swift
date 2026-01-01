//
//  TeamLinkView.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import SwiftUI

struct TeamLinkView<Content: View>: View {
    let teamId: String?
    let content: Content
    
    init(teamId: String?, @ViewBuilder content: () -> Content) {
        self.teamId = teamId
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            // On vérifie qu'on a bien un ID valide
            if let id = teamId, !id.isEmpty {
                
                // ✅ ENVOI DE LA NOTIFICATION À MAINGAMEVIEW
                // Cela demande à l'écran principal de :
                // 1. Changer l'onglet actif vers .club
                // 2. Mettre à jour le contexte avec l'ID de ce club
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToClub"),
                    object: nil,
                    userInfo: ["clubId": id]
                )
            }
        }) {
            content
        }
        .buttonStyle(PlainButtonStyle()) // Important : Garde le style visuel de votre contenu (pas de bleu par défaut)
    }
}
