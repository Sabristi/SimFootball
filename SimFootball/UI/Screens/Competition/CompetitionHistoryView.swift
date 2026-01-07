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
    
    // On détecte le type de compétition pour adapter l'affichage
    var isCup: Bool {
        if let comp = GameDatabase.shared.competitions.first(where: { $0.id == competitionId }) {
            return comp.type == .cup
        }
        return false
    }
    
    private let editionWidth: CGFloat = 85
    
    var body: some View {
        VStack(spacing: 0) {
            // EN-TÊTES (DYNAMIQUE)
            HStack(spacing: 0) {
                Text("Édition").frame(width: editionWidth, alignment: .leading)
                
                if isCup {
                    Text("Vainqueur 🏆").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4)
                    Text("Finaliste 🥈").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4)
                    Text("Demi-Finalistes").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4)
                } else {
                    Text("Champion 🥇").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4)
                    Text("Vice-Champion 🥈").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4)
                    Text("3ème Place 🥉").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4)
                }
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
                        ForEach(historyEntries, id: \.id) { entry in
                            CompetitionHistoryRow(entry: entry, editionWidth: editionWidth, isCup: isCup)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}

// LIGNE D'HISTORIQUE (ADAPTATIVE)
struct CompetitionHistoryRow: View {
    let entry: CompetitionHistoryEntry
    let editionWidth: CGFloat
    let isCup: Bool
    
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
                // Image(systemName: "trophy.fill").font(.caption2).foregroundColor(.yellow)
                TeamCell(clubId: entry.winnerId, isWinner: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            
            // 2ÈME (FINALISTE OU VICE-CHAMPION)
            TeamCell(clubId: entry.runnerUpId)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
            
            // 3ÈME COLONNE (3ÈME PLACE ou DEMI-FINALISTES)
            if isCup {
                // Pour la coupe, on affiche les deux demi-finalistes (si disponibles)
                VStack(alignment: .leading, spacing: 2) {
                    if let semis = entry.semiFinalistsIds, !semis.isEmpty {
                        ForEach(semis.prefix(2), id: \.self) { semiId in
                            TeamCell(clubId: semiId, fontSize: 10)
                        }
                    } else {
                        Text("-").font(.caption2).foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
                
            } else {
                // Pour le championnat, on affiche juste le 3ème
                TeamCell(clubId: entry.thirdPlaceId)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - CELLULE D'ÉQUIPE (AMÉLIORÉE)
struct TeamCell: View {
    let clubId: String?
    var isWinner: Bool = false
    var fontSize: CGFloat = 11 // Permet de réduire la taille pour les demi-finalistes
    
    var body: some View {
        HStack(spacing: 6) {
            if let id = clubId, let club = GameDatabase.shared.getClub(byId: id) {
                
                // LOGO (Utilisation de la nouvelle logique PlatformImage)
                if let image = PlatformImage(named: club.id) {
                    Image(platformImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: isWinner ? 24 : 20, height: isWinner ? 24 : 20)
                } else {
                    // Fallback
                    Circle()
                        .fill(Color(hex: club.identity.primaryColor))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text(String(club.shortName.prefix(1)))
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                // NOM DU CLUB
                Text(club.shortName)
                    .font(.system(size: fontSize, weight: isWinner ? .bold : .medium))
                    .foregroundColor(isWinner ? .white : .gray.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
            } else {
                // Pas de club
                Text("-")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.3))
            }
        }
    }
}
