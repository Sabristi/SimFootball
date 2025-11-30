//
//  SaveSlotCard.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 23/11/2025.
//

import SwiftUI

struct SaveSlotCard: View {
    let slot: SaveSlot
    let onAction: () -> Void      // Clic principal (Charger/Créer)
    let onDelete: () -> Void      // Clic suppression
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            // --- 1. LE BOUTON PRINCIPAL (FOND DE CARTE) ---
            Button(action: onAction) {
                ZStack {
                    // FOND
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            slot.isEmpty
                            ? Color.white.opacity(0.05)
                            : Color.green.opacity(0.15)
                        )
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    slot.isEmpty ? Color.white.opacity(0.2) : Color.green.opacity(0.5),
                                    style: StrokeStyle(lineWidth: 1, dash: slot.isEmpty ? [5] : [])
                                )
                        )

                    // CONTENU
                    VStack(spacing: 10) {
                        if slot.isEmpty {
                            // --- MODE VIDE ---
                            Image(systemName: "plus")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("Empty Slot \(slot.id)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("Start New Career")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.2))
                            
                        } else {
                            // --- MODE OCCUPÉ ---
                            Image(systemName: "shield.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.5), radius: 5)
                            
                            VStack(spacing: 4) {
                                Text(slot.teamName ?? "Unknown Mode")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                // Affichage de la date simulée (ex: 15 Jul 2025)
                                Text(slot.lastPlayed?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown Date")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2)) // Fond vert léger pour la date
                                    .cornerRadius(6)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Image(systemName: "calendar")
                                Text("Season \(slot.seasonYear ?? "2025")")
                            }
                            .font(.caption2)
                            .foregroundColor(.gray)
                        }
                    }
                    .padding(20)
                }
            }
            .buttonStyle(BouncyButtonStyle()) // Ton style d'animation
            
            // --- 2. LE BOUTON SUPPRIMER (POUBELLE) ---
            // Uniquement si le slot n'est PAS vide
            if !slot.isEmpty {
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title)
                        .foregroundColor(.red.opacity(0.8))
                        .background(Color.black.clipShape(Circle())) // Petit fond noir pour la lisibilité
                }
                .padding(10)
                .buttonStyle(PlainButtonStyle()) // Important pour ne pas cliquer sur la carte en même temps
            }
        }
    }
}
