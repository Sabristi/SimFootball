//
//  CompetitionDrawView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 03/12/2025.
//

import SwiftUI

struct CompetitionDrawView: View {
    let competitionId: String
    let seasonId: String // ID de la saison cible (ex: "S_2026_27")
    let onClose: () -> Void
    let onComplete: () -> Void // Callback quand le tirage est fini
    
    @State private var participants: [Club] = []
    @State private var isProcessing: Bool = false
    @State private var drawCompleted: Bool = false
    @State private var isLoadingData: Bool = true
    
    // Pour afficher le nom de la compétition
    var competitionName: String {
        GameDatabase.shared.competitions.first(where: { $0.id == competitionId })?.shortName.uppercased() ?? "COMPÉTITION"
    }
    
    var body: some View {
        ZStack {
            // 1. FOND FLOU
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { if !isProcessing { onClose() } }
            
            // 2. LA FENÊTRE POPUP
            VStack(spacing: 0) {
                
                // HEADER
                HStack {
                    Image(systemName: "trophy.circle.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                    
                    Text("TIRAGE AU SORT : \(competitionName)")
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .disabled(isProcessing)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                
                // CONTENU
                VStack(spacing: 20) {
                    
                    // Affichage joli de la saison
                    let seasonLabel = seasonId
                        .replacingOccurrences(of: "S_", with: "")
                        .replacingOccurrences(of: "_", with: "/")
                    
                    Text("Participants Saison \(seasonLabel)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 10)
                    
                    // --- GRILLE DES CLUBS ---
                    if isLoadingData {
                        VStack(spacing: 15) {
                            ProgressView().tint(.yellow)
                            Text("Chargement des participants...")
                                .font(.caption).foregroundColor(.gray)
                        }.frame(height: 200)
                        
                    } else if participants.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle).foregroundColor(.orange)
                            Text("Aucun participant trouvé.")
                                .font(.headline).foregroundColor(.white)
                            Text("Vérifiez la configuration de la saison \(seasonId).")
                                .font(.caption).foregroundColor(.gray)
                        }.frame(height: 200)
                        
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(participants) { club in
                                    HStack(spacing: 10) {
                                        ClubLogoView(clubId: club.id, size: 32)
                                        
                                        Text(club.name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.9)
                                        
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 300)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // BOUTON D'ACTION
                    if drawCompleted {
                        VStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.largeTitle).foregroundColor(.green)
                            Text("Calendrier Généré !")
                                .font(.headline).foregroundColor(.green)
                        }
                        .padding()
                        .transition(.scale)
                    } else {
                        Button(action: startDrawProcess) {
                            HStack {
                                if isProcessing {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "shuffle")
                                }
                                Text(isProcessing ? "GÉNÉRATION EN COURS..." : "GÉNÉRER LE CALENDRIER")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(participants.isEmpty ? Color.gray : Color.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .shadow(color: .yellow.opacity(0.3), radius: 10)
                        }
                        .disabled(isProcessing || participants.isEmpty)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .frame(width: 600)
            .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
            .shadow(radius: 20)
        }
        .onAppear {
            loadData()
        }
    }
    
    // --- LOGIQUE INTERNE ---
    
    func loadData() {
        self.isLoadingData = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // ✅ 1. Récupération générique via GameDatabase
            if let config = GameDatabase.shared.getCompetitionSeason(competitionId: competitionId, seasonId: seasonId) {
                
                // On transforme les IDs en objets Club
                let clubs = config.teamIds.compactMap { GameDatabase.shared.getClub(byId: $0) }
                self.participants = clubs.sorted { $0.name < $1.name }
                
            } else {
                print("⚠️ Aucune configuration trouvée pour \(competitionId) / \(seasonId)")
                self.participants = []
            }
            
            withAnimation { self.isLoadingData = false }
        }
    }
    
    func startDrawProcess() {
        withAnimation { isProcessing = true }
        
        // Simulation de suspense...
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            
            // ✅ 2. Appel au NOUVEAU service générique
            let success = CompetitionDrawService.shared.performDrawForLeague(
                competitionId: competitionId,
                seasonId: seasonId
            )
            
            if success {
                withAnimation {
                    isProcessing = false
                    drawCompleted = true
                }
                
                // Fermeture auto
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onComplete()
                }
            } else {
                print("❌ Échec du tirage")
                isProcessing = false
            }
        }
    }
}
