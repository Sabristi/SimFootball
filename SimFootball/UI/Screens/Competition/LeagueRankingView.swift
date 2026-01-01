//
//  LeagueRankingView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 28/12/2025.
//

import SwiftUI

struct LeagueRankingView: View {
    let competitionId: String
    let seasonId: String
    var isCompact: Bool = false
    @State private var selectedFilter: String = "General"
    
    // Récupérer la compétition pour avoir les règles de couleurs (slots)
    var competition: Competition? {
        GameDatabase.shared.competitions.first(where: { $0.id == competitionId })
    }
    
    var rankingEntries: [LeagueTableEntry] {
        let fullTable = GameDatabase.shared.getLeagueTable(competitionId: competitionId, seasonId: seasonId)
        if isCompact { return Array(fullTable.prefix(8)) }
        return fullTable
    }
    
    private let statWidth: CGFloat = 35
    
    var body: some View {
        VStack(spacing: 0) {
            
            // FILTRE (Seulement en vue complète)
            if !isCompact {
                HStack {
                    Spacer()
                    Menu { Button("General") { selectedFilter = "General" } } label: {
                        HStack(spacing: 6) {
                            Text(selectedFilter).font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                            Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .menuIndicator(.hidden)
                }
                .padding(.bottom, 10)
                .padding(.horizontal, 20)
            }
            
            // TABLEAU
            VStack(spacing: 0) {
                
                // HEADER
                HStack(spacing: 0) {
                    Text("POS").frame(width: 40)
                    Text("CLUB").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 8)
                    Group {
                        Text("PL").frame(width: statWidth)
                        if !isCompact {
                            Text("V").frame(width: statWidth); Text("N").frame(width: statWidth)
                            Text("D").frame(width: statWidth); Text("B").frame(width: statWidth); Text("Bc").frame(width: statWidth)
                        }
                        Text("GD").frame(width: 40)
                        Text("PTS").frame(width: 40)
                    }
                    if !isCompact { Text("FORME").frame(width: 100) }
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.03))
                
                // LISTE
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(rankingEntries.enumerated()), id: \.offset) { index, entry in
                            let club = GameDatabase.shared.getClub(byId: entry.teamId)
                            let clubName = isCompact ? (club?.shortName ?? entry.teamAlias) : (club?.name ?? entry.teamAlias)
                            let rank = index + 1
                            
                            HStack(spacing: 0) {
                                
                                // 1. POSITION (Avec Couleur Dynamique)
                                ZStack {
                                    // Barre latérale de couleur (si définie)
                                    if let color = getPositionColor(for: rank) {
                                        Rectangle()
                                            .fill(color)
                                            .frame(width: 4)
                                            .frame(maxHeight: .infinity)
                                            .offset(x: -18) // Coller au bord gauche
                                    }
                                    
                                    Text("\(rank)")
                                        .font(.caption).bold()
                                        .foregroundColor(.white)
                                }
                                .frame(width: 40)
                                
                                // 2. CLUB
                                HStack(spacing: 8) {
                                    ClubLogoView(clubId: entry.teamId, size: 24)
                                    // ✅ Navigation vers le club au clic
                                    TeamLinkView(teamId: entry.teamId) {
                                        Text(clubName)
                                            .fontWeight(.semibold)
                                            .lineLimit(1)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)
                                
                                // 3. STATS
                                Group {
                                    Text("\(entry.played)").frame(width: statWidth).foregroundColor(.white)
                                    if !isCompact {
                                        Text("\(entry.won)").frame(width: statWidth).foregroundColor(.gray)
                                        Text("\(entry.drawn)").frame(width: statWidth).foregroundColor(.gray)
                                        Text("\(entry.lost)").frame(width: statWidth).foregroundColor(.gray)
                                        Text("\(entry.goalsFor)").frame(width: statWidth).foregroundColor(.gray)
                                        Text("\(entry.goalsAgainst)").frame(width: statWidth).foregroundColor(.gray)
                                    }
                                    Text("\(entry.goalDifference)")
                                        .frame(width: 40)
                                        .foregroundColor(entry.goalDifference > 0 ? .green : (entry.goalDifference < 0 ? .red : .gray))
                                    Text("\(entry.points)")
                                        .bold()
                                        .frame(width: 40)
                                        .foregroundColor(.yellow)
                                }
                                .font(.system(size: 12))
                                
                                // 4. FORME
                                if !isCompact {
                                    HStack(spacing: 4) {
                                        let recentForm = entry.form.suffix(5)
                                        if recentForm.isEmpty {
                                            ForEach(0..<5, id: \.self) { _ in Circle().fill(Color.white.opacity(0.1)).frame(width: 8, height: 8) }
                                        } else {
                                            ForEach(Array(recentForm), id: \.self) { result in FormBadge(result: result) }
                                            if recentForm.count < 5 { ForEach(0..<(5 - recentForm.count), id: \.self) { _ in Circle().fill(Color.white.opacity(0.1)).frame(width: 8, height: 8) } }
                                        }
                                    }.frame(width: 100)
                                }
                            }
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(index % 2 == 0 ? 0.05 : 0.02))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .background(Color.black.opacity(0.2))
            .cornerRadius(isCompact ? 0 : 12)
            .padding(.horizontal, isCompact ? 0 : 20)
            .padding(.bottom, isCompact ? 0 : 20)
        }
        .padding(.top, isCompact ? 0 : 20)
    }
    
    // ✅ HELPER POUR LA COULEUR DE LA POSITION
    private func getPositionColor(for rank: Int) -> Color? {
        guard let slots = competition?.positionSlots else {
            // Fallback par défaut si pas de slots configurés
            if rank <= 2 { return .green } // LDC
            if rank == 3 { return .yellow } // CAF
            if rank >= 15 { return .red }   // Relégation
            return nil
        }
        
        // On cherche une règle pour ce rang précis
        if let slot = slots.first(where: { $0.rank == rank }) {
            return Color(hex: slot.colorHex ?? "#FFFFFF")
        }
        
        return nil
    }
}
