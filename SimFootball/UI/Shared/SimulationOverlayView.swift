//
//  SimulationOverlayView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 03/12/2025.
//

import SwiftUI

struct SimulationOverlayView: View {
    // Liste des matchs À JOUER aujourd'hui
    let matchesToSimulate: [Match]
    
    // Callback fin
    let onComplete: () -> Void
    
    // États
    @State private var progress: CGFloat = 0.0
    @State private var processedMatches: [Match] = []
    @State private var currentMatchIndex: Int = 0
    
    var body: some View {
        ZStack {
            // Fond semi-transparent
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 15) { // Espacement réduit
                
                // TITRE COMPACT
                HStack {
                    Image(systemName: "sportscourt.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("LIVE SIMULATION")
                        .font(.subheadline).fontWeight(.heavy) // Plus petit
                        .foregroundColor(.white).tracking(1)
                }
                .padding(.top, 5)
                
                // BARRE DE PROGRESSION (Minimaliste, sans texte)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                        Capsule().fill(Color.green).frame(width: geo.size.width * progress, height: 4)
                            .animation(.linear(duration: 0.2), value: progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                
                // LISTE DES RÉSULTATS COMPACTE
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(processedMatches) { match in
                                ResultRow(match: match)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .id(match.id)
                            }
                            
                            // Petit espace en bas
                            Color.clear.frame(height: 20).id("bottom")
                        }
                        .padding(.horizontal, 10)
                    }
                    .frame(height: 200) // Hauteur réduite
                    .mask(LinearGradient(gradient: Gradient(colors: [.clear, .black, .black, .clear]), startPoint: .top, endPoint: .bottom))
                    .onChange(of: processedMatches.count) { _ in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                
                // TEXTE DISCRET
                Text("Processing matches...")
                    .font(.caption2).italic().foregroundColor(.gray.opacity(0.5))
            }
            .frame(width: 400) // Largeur réduite
            .padding(20)       // Padding réduit
            .background(Color(hex: "1A1A1A"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(radius: 20)
        }
        .onAppear {
            startSimulationSequence()
        }
    }
    
    // --- LOGIQUE DE SÉQUENCEMENT (INCHANGÉE) ---
    
    func startSimulationSequence() {
        guard !matchesToSimulate.isEmpty else {
            DispatchQueue.main.async { onComplete() }
            return
        }
        
        let simulatedResults = SimulationEngine.shared.simulateMatches(matchesToSimulate)
        let totalTimePerMatch = 0.6 // Un peu plus rapide aussi
        
        Timer.scheduledTimer(withTimeInterval: totalTimePerMatch, repeats: true) { timer in
            if currentMatchIndex < simulatedResults.count {
                let match = simulatedResults[currentMatchIndex]
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    processedMatches.append(match)
                }
                
                currentMatchIndex += 1
                progress = CGFloat(currentMatchIndex) / CGFloat(simulatedResults.count)
                
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
}

// Sous-vue ResultRow (Version Compacte)
struct ResultRow: View {
    let match: Match
    
    var homeName: String { GameDatabase.shared.getClub(byId: match.homeTeamId ?? "")?.shortName ?? "Home" }
    var awayName: String { GameDatabase.shared.getClub(byId: match.awayTeamId ?? "")?.shortName ?? "Away" }
    
    var body: some View {
        HStack {
            // Home
            HStack(spacing: 6) {
                Text(homeName).font(.caption).fontWeight(.bold).lineLimit(1)
                Spacer()
                if let id = match.homeTeamId { ClubLogoView(clubId: id, size: 20) }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Score Box
            HStack(spacing: 0) {
                Text("\(match.homeTeamGoals ?? 0)").frame(width: 20)
                Text("-")
                Text("\(match.awayTeamGoals ?? 0)").frame(width: 20)
            }
            .font(.callout).fontWeight(.black)
            .foregroundColor(.yellow)
            .frame(width: 50)
            .background(Color.black.opacity(0.3))
            .cornerRadius(4)
            
            // Away
            HStack(spacing: 6) {
                if let id = match.awayTeamId { ClubLogoView(clubId: id, size: 20) }
                Spacer()
                Text(awayName).font(.caption).fontWeight(.bold).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
        .foregroundColor(.white)
    }
}
