//
//  ClubKitsEditorView.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import SwiftUI

struct ClubKitsEditorView: View {
    @Binding var club: Club
    @Environment(\.dismiss) var dismiss
    
    // État pour l'onglet sélectionné
    @State private var selectedKitType: KitType = .home
    
    var body: some View {
        NavigationStack {
            // MISE EN PAGE : HSTACK pour séparer Gauche (Visuel) / Droite (Contrôles)
            HStack(spacing: 0) {
                
                // ------------------------------------------------
                // COLONNE GAUCHE : APERÇU VISUEL (Fixe)
                // ------------------------------------------------
                ZStack {
                    // Fond style "Pelouse" ou "Vestiaire"
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [Color(hex: "#2c3e50"), Color(hex: "#000000")], startPoint: .top, endPoint: .bottom)
                        )
                        .ignoresSafeArea()
                    
                    // Cercle lumineux derrière le maillot
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .blur(radius: 20)
                        .frame(width: 250, height: 250)
                    
                    if let index = currentKitIndex {
                        // Le Kit Renderer (Affiche Maillot + Short + Chaussettes car vos PNG contiennent tout)
                        KitRendererView(kit: club.kits[index])
                            .frame(width: 220) // Taille généreuse
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 10)
                            .id(club.kits[index].hashValue) // Force le rafraîchissement si modif
                    } else {
                        // État vide
                        VStack {
                            Image(systemName: "tshirt")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.2))
                            Text("Maillot non défini")
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top)
                        }
                    }
                }
                .frame(width: 300) // Largeur fixe pour la colonne de gauche
                
                // ------------------------------------------------
                // COLONNE DROITE : ÉDITEUR (Scrollable)
                // ------------------------------------------------
                VStack(spacing: 0) {
                    
                    // Barre d'onglets (Home / Away / Third)
                    Picker("Type", selection: $selectedKitType) {
                        Text("DOMICILE").tag(KitType.home)
                        Text("EXTÉRIEUR").tag(KitType.away)
                        Text("THIRD").tag(KitType.third)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            if let index = currentKitIndex {
                                // --- FORMULAIRE D'ÉDITION ---
                                
                                // 1. CHOIX DU DESIGN (Pattern)
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("STYLE & DESIGN").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                                    
                                    Picker("Modèle", selection: $club.kits[index].pattern) {
                                        ForEach(KitPattern.allCases, id: \.self) { pattern in
                                            Text(pattern.displayName).tag(pattern)
                                        }
                                    }
                                    .pickerStyle(.menu) // Menu déroulant propre
                                }
                                .padding(.horizontal)
                                
                                Divider()
                                
                                // 2. COULEURS DU MAILLOT
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("COULEURS MAILLOT").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                                    
                                    // Logique extraite pour les couleurs
                                    JerseyColorsEditor(kit: $club.kits[index])
                                }
                                .padding(.horizontal)
                                
                                Divider()
                                
                                // 3. SHORT ET CHAUSSETTES
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("BAS DU CORPS").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                                    
                                    KitColorRow(label: "Short", colorHex: $club.kits[index].shortsColor)
                                    KitColorRow(label: "Chaussettes", colorHex: $club.kits[index].socksColor)
                                }
                                .padding(.horizontal)
                                
                                // 4. ACTIONS (Supprimer)
                                if selectedKitType != .home {
                                    Divider()
                                    Button(role: .destructive, action: {
                                        deleteKit(at: index)
                                    }) {
                                        Label("Supprimer ce maillot", systemImage: "trash")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .controlSize(.large)
                                    .padding()
                                }
                                
                            } else {
                                // --- BOUTON DE CRÉATION ---
                                VStack(spacing: 20) {
                                    Spacer()
                                    Text("Ce maillot n'existe pas encore.")
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: createKit) {
                                        Text("Créer le maillot \(selectedKitType.rawValue)")
                                            .fontWeight(.semibold)
                                            .frame(width: 200)
                                    }
                                    .controlSize(.large)
                                    .buttonStyle(.borderedProminent)
                                    Spacer()
                                }
                                .frame(height: 300)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .background(Color(NSColor.windowBackgroundColor)) // Couleur de fond native Mac
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        // Force une taille "Pop-up" large sur Mac
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 500)
        #endif
    }
    
    // MARK: - Helpers
    
    // Trouve l'index du kit actuel
    var currentKitIndex: Int? {
        club.kits.firstIndex(where: { $0.type == selectedKitType })
    }
    
    func createKit() {
        let newKit = Kit(
            type: selectedKitType,
            pattern: .classic, // Default safe pattern
            jerseyColors: ["#FFFFFF"],
            shortsColor: "#000000",
            socksColor: "#FFFFFF"
        )
        withAnimation {
            club.kits.append(newKit)
        }
    }
    
    func deleteKit(at index: Int) {
        withAnimation {
            _ = club.kits.remove(at: index)
        }
    }
}

// MARK: - SOUS-VUES EXTRAITES

struct JerseyColorsEditor: View {
    @Binding var kit: Kit
    
    var body: some View {
        VStack(spacing: 8) {
            
            // 1. COULEUR DE FOND (Toujours visible - Index 0)
            if kit.jerseyColors.indices.contains(0) {
                KitColorRow(label: "Couleur Principale", colorHex: $kit.jerseyColors[0])
            }
            
            // Si le maillot n'est pas "Uni" (Solid), on propose les motifs
            if kit.pattern != .solid {
                
                // 2. MOTIF 1 (Index 1 - Correspond au Cyan #00FFFF)
                if kit.jerseyColors.count > 1 {
                    KitColorRow(label: "Motif 1 (Principal)", colorHex: $kit.jerseyColors[1], onDelete: {
                        // On permet de supprimer le motif pour revenir à l'uni
                        if kit.jerseyColors.count > 1 {
                             _ = kit.jerseyColors.remove(at: 1)
                        }
                    })
                } else {
                    // Bouton pour activer le Motif 1
                    addInfoButton(text: "+ Ajouter Motif 1") {
                        kit.jerseyColors.append("#FFFFFF") // Blanc par défaut
                    }
                }
                
                // 3. MOTIF 2 (Index 2 - Correspond au Rouge #FF0000)
                if kit.jerseyColors.count > 2 {
                    KitColorRow(label: "Motif 2 (Secondaire)", colorHex: $kit.jerseyColors[2], onDelete: {
                        // On supprime l'index 2
                        _ = kit.jerseyColors.remove(at: 2)
                    })
                } else if kit.jerseyColors.count == 2 {
                    // Bouton pour activer le Motif 2 (seulement si Motif 1 existe déjà)
                    addInfoButton(text: "+ Ajouter Motif 2") {
                        kit.jerseyColors.append("#000000") // Noir par défaut
                    }
                }
            }
            
            Divider().padding(.vertical, 5)
            
            Text("DÉTAILS").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 4. DÉTAILS SPÉCIFIQUES
            KitColorRow(label: "Col", colorHex: $kit.collarColor)
            KitColorRow(label: "Sponsor", colorHex: $kit.sponsorColor)
            KitColorRow(label: "Logo Club", colorHex: $kit.logoColor)
        }
    }
    
    // Petit helper pour le style des boutons "Ajouter"
    func addInfoButton(text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(text)
                Spacer()
            }
            .padding(6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct KitColorRow: View {
    let label: String
    @Binding var colorHex: String
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(label).font(.body)
            Spacer()
            
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            ColorPicker("", selection: binding(for: $colorHex))
                .labelsHidden()
                .scaleEffect(0.9) // Un peu plus discret
        }
        .padding(8)
        .background(Color.white.opacity(0.05)) // Fond léger pour la ligne
        .cornerRadius(6)
    }
}
