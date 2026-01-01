//
//  SideMenuPanel.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 30/11/2025.
//

import SwiftUI

struct SideMenuPanel: View {
    let title: String           // Titre du menu (ex: "MOROCCO")
    let headerIcon: String      // Emoji ou Icône (ex: "🇲🇦")
    let items: [SideMenuItem]   // Liste des boutons
    
    @Binding var isPresented: Bool // Pour fermer le menu
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            // 1. FOND FLOU (Overlay)
            // Cliquer ici ferme le menu
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
                .transition(.opacity)
            
            // 2. LE PANNEAU LATÉRAL
            VStack(spacing: 0) {
                
                // HEADER DU MENU
                VStack(spacing: 10) {
                    Text(headerIcon)
                        .font(.system(size: 50))
                        .shadow(color: .black.opacity(0.5), radius: 5)
                    
                    Text(title.uppercased())
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color(hex: "1A1A2E")) // Fond Header
                
                // LISTE DES BOUTONS
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(items) { item in
                            Button(action: {
                                // 1. Exécuter l'action
                                item.action()
                                // 2. Fermer le menu
                                withAnimation { isPresented = false }
                            }) {
                                HStack(spacing: 15) {
                                    // Barre de couleur FM Style
                                    Rectangle()
                                        .fill(item.color)
                                        .frame(width: 4)
                                        .cornerRadius(2)
                                        .padding(.vertical, 6)
                                    
                                    Image(systemName: item.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                        .frame(width: 24)
                                    
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.2))
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 50)
                                .background(Color.white.opacity(0.03))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 10)
                }
                .background(Color(hex: "121212")) // Fond Liste
                
                // PIED DE PAGE (Bouton Fermer)
                Button(action: {
                    withAnimation { isPresented = false }
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Close Menu")
                    }
                    .font(.caption).bold()
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "0F0F0F"))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: 260) // Largeur fixe du panneau
            .background(Color(hex: "121212"))
            .overlay(
                Rectangle().frame(width: 1).foregroundColor(.white.opacity(0.1)),
                alignment: .trailing
            )
            .transition(.move(edge: .leading)) // Animation de glissement
        }
        .zIndex(100) // Toujours au-dessus de tout le reste
    }
}
