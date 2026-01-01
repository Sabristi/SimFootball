//
//  CompetitionHistoryView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 14/12/2025.
//

import SwiftUI

struct CompetitionHistoryView: View {
    let competitionId: String
    
    // Accès direct sécurisé
    var historyEntries: [CompetitionHistoryEntry] {
        guard let save = GameDatabase.shared.currentSave else { return [] }
        return save.competitionHistory
            .filter { $0.competitionId == competitionId }
            .sorted { $0.edition > $1.edition }
    }
    
    private let editionWidth: CGFloat = 85
    
    var body: some View {
        VStack(spacing: 0) {
            // EN-TÊTES
            HStack(spacing: 0) {
                Text("Édition").frame(width: editionWidth, alignment: .leading)
                Text("Vainqueur").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4)
                Text("2ème").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4)
                Text("3ème").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.gray)
            .padding(16)
            .background(Color.black.opacity(0.3))
            
            // LISTE
            ScrollView {
                VStack(spacing: 8) {
                    if historyEntries.isEmpty {
                        Text("Aucun historique disponible")
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    } else {
                        // Utilisation de Array et id: \.id pour aider le compilateur
                        ForEach(historyEntries, id: \.id) { entry in
                            CompetitionHistoryRow(entry: entry, editionWidth: editionWidth)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}

// LA LIGNE EXTRAITE (Indispensable pour éviter l'erreur de timeout du compilateur)
struct CompetitionHistoryRow: View {
    let entry: CompetitionHistoryEntry
    let editionWidth: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            // ANNÉE
            Text(entry.edition)
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .frame(width: editionWidth, alignment: .leading)
            
            // VAINQUEUR
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill").font(.caption2).foregroundColor(.yellow)
                TeamCell(clubId: entry.winnerId, isWinner: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            
            // 2ÈME
            TeamCell(clubId: entry.runnerUpId)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
            
            // 3ÈME
            TeamCell(clubId: entry.thirdPlaceId)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - CELLULE D'ÉQUIPE
struct TeamCell: View {
    let clubId: String?
    var isWinner: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            if let id = clubId, let club = GameDatabase.shared.getClub(byId: id) {
                
                let logoName = club.id
                
                // On vérifie si l'image existe
                if checkAssetExists(logoName) {
                    Image(logoName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                } else {
                    // Fallback : Cercle de couleur si pas de logo
                    Circle()
                        .fill(Color(hex: club.identity.primaryColor))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Text(String(club.shortName.prefix(1)))
                                .font(.caption2).bold().foregroundColor(.white)
                        )
                }
                
                // NOM DU CLUB
                Text(club.shortName)
                    .font(.system(size: 11, weight: isWinner ? .bold : .medium))
                    .foregroundColor(isWinner ? .white : .gray.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
            } else {
                // Pas de club (ex: bug de données)
                Text("-")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.3))
            }
        }
    }
    
    // MARK: - FONCTION DE VÉRIFICATION
    // Cette fonction détecte si on est sur Mac ou iOS pour utiliser le bon type d'image
    func checkAssetExists(_ name: String) -> Bool {
        #if os(macOS)
        // Sur macOS, on utilise NSImage
        return NSImage(named: name) != nil
        #else
        // Sur iOS, on utilise UIImage
        return UIImage(named: name) != nil
        #endif
    }
}
