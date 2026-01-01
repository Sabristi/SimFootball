//
//  CupDrawView.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import SwiftUI

struct CupDrawView: View {
    @StateObject var viewModel: CupDrawViewModel
    
    // Callback pour prévenir MainGameView de fermer la popup
    var onDismiss: (() -> Void)?
    
    // Initialiseur
    init(roundId: String, seasonId: String, onDismiss: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: CupDrawViewModel(roundId: roundId, seasonId: seasonId))
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            // Fond sombre dégradé (Style TV)
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.15, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // 1. EN-TÊTE
                headerView
                
                // 2. ZONE PRINCIPALE (Split View)
                HStack(spacing: 0) {
                    
                    // COLONNE GAUCHE : Le Saladier (Équipes restantes)
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "archivebox")
                            Text("SALADIER (\(viewModel.pot.count))")
                        }
                        .font(.caption).fontWeight(.bold).foregroundColor(.gray).padding(.bottom, 5)
                        
                        ScrollView {
                            // GRILLE DES PARTICIPANTS
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                                ForEach(viewModel.pot.reversed(), id: \.id) { club in
                                    VStack(spacing: 5) {
                                        ClubLogoView(clubId: club.id, size: 30)
                                        Text(club.shortName)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    .frame(height: 60)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                    // Animation de disparition quand l'équipe est tirée
                                    .transition(.scale)
                                }
                            }
                            .padding(5)
                        }
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .padding()
                    .frame(width: 300) // Largeur fixe pour la colonne de gauche
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // COLONNE DROITE : Animation & Résultats
                    VStack(spacing: 0) {
                        
                        // ZONE D'ANIMATION (La boule tirée)
                        ZStack {
                            if let team = viewModel.lastDrawnTeam {
                                VStack(spacing: 15) {
                                    Text("ÉQUIPE TIRÉE")
                                        .font(.caption).fontWeight(.black).foregroundColor(.yellow).tracking(2)
                                    
                                    ClubLogoView(clubId: team.id, size: 90)
                                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                                    
                                    Text(team.name.uppercased())
                                        .font(.title)
                                        .fontWeight(.black)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding(30)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.05))
                                        .background(.ultraThinMaterial) // Effet de flou
                                        .cornerRadius(20)
                                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                )
                                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                                .id("DrawCard_\(team.id)") // Force l'animation à chaque changement
                                
                            } else {
                                // Placeholder avant le début
                                VStack(spacing: 10) {
                                    Image(systemName: "shuffle")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.1))
                                    Text("En attente du tirage...")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                        }
                        .frame(height: 250) // Hauteur fixe pour la zone d'animation
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.1))
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // LISTE DES MATCHS GÉNÉRÉS
                        VStack(alignment: .leading, spacing: 5) {
                            Text("TABLEAU DES RENCONTRES")
                                .font(.caption).fontWeight(.bold).foregroundColor(.gray).padding(.top, 10).padding(.horizontal)
                            
                            ScrollViewReader { proxy in
                                ScrollView {
                                    VStack(spacing: 0) {
                                        // Match en cours (Brouillon)
                                        if let active = viewModel.currentPair {
                                            activeMatchRow(active)
                                                .padding(.horizontal)
                                                .padding(.bottom, 5)
                                        }
                                        
                                        // Matchs validés
                                        ForEach(viewModel.drawnPairs.reversed()) { pair in
                                            completedMatchRow(pair)
                                                .padding(.horizontal)
                                                .padding(.vertical, 4)
                                                .transition(.move(edge: .top))
                                        }
                                    }
                                    .padding(.bottom, 20)
                                }
                                .onChange(of: viewModel.drawnPairs.count) { _ in
                                    // Scroll auto vers le haut quand un match est ajouté
                                    withAnimation { proxy.scrollTo(viewModel.drawnPairs.last?.id, anchor: .top) }
                                }
                            }
                        }
                    }
                }
                
                // 3. BARRE D'ACTIONS (BAS)
                actionBottomBar
            }
        }
        .onAppear {
            print("👀 [DEBUG] CupDrawView affichée.")
            viewModel.loadQualifiedTeams()
        }
    }
    
    // MARK: - SOUS-VUES
    
    var headerView: some View {
        HStack {
            Image(systemName: "trophy.fill").foregroundColor(.yellow)
            Text("COUPE DU TRÔNE - TIRAGE AU SORT")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .tracking(1)
            
            Spacer()
            
            // Badge Statut
            Text(viewModel.isFinished ? "TERMINÉ" : "EN COURS")
                .font(.caption2)
                .fontWeight(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(viewModel.isFinished ? Color.green : Color.orange)
                .foregroundColor(.black)
                .cornerRadius(4)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    var actionBottomBar: some View {
        HStack(spacing: 20) {
            if !viewModel.isFinished {
                Button(action: {
                    withAnimation { viewModel.simulateRemaining() }
                }) {
                    HStack {
                        Image(systemName: "forward.end.fill")
                        Text("Simuler Tout")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding()
                    .foregroundColor(.white.opacity(0.8))
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation { viewModel.drawNextBall() }
                }) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                        Text(viewModel.currentPair == nil ? "Tirer Équipe A (Domicile)" : "Tirer Équipe B (Extérieur)")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding()
                    .frame(width: 300)
                    .background(viewModel.currentPair == nil ? Color.blue : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
                
            } else {
                Spacer()
                Button(action: {
                    viewModel.confirmDrawAndSave {
                        onDismiss?()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Valider le Calendrier")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding()
                    .frame(width: 300)
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .shadow(color: .green.opacity(0.4), radius: 10)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
    }
    
    // Ligne pour le match en cours de construction
    func activeMatchRow(_ pair: CupPairing) -> some View {
        HStack {
            // Home
            HStack {
                Text(pair.homeTeam?.name ?? "?")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                if let id = pair.homeTeam?.id { ClubLogoView(clubId: id, size: 24) }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text("VS")
                .font(.caption).fontWeight(.black)
                .padding(6)
                .background(Color.yellow)
                .foregroundColor(.black)
                .clipShape(Circle())
            
            // Away
            HStack {
                if let id = pair.awayTeam?.id { ClubLogoView(clubId: id, size: 24) }
                Text(pair.awayTeam?.name ?? "...")
                    .fontWeight(.bold)
                    .foregroundColor(pair.awayTeam != nil ? .white : .gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.yellow, style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
        .background(Color.yellow.opacity(0.05))
    }
    
    // Ligne pour un match terminé
    func completedMatchRow(_ pair: CupPairing) -> some View {
        HStack {
            HStack {
                Text(pair.homeTeam?.name ?? "")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                if let id = pair.homeTeam?.id { ClubLogoView(clubId: id, size: 20) }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text("-")
                .foregroundColor(.gray)
                .frame(width: 20)
            
            HStack {
                if let id = pair.awayTeam?.id { ClubLogoView(clubId: id, size: 20) }
                Text(pair.awayTeam?.name ?? "")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
    }
}
