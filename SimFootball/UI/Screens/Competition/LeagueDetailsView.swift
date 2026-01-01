//
//  LeagueDetailsView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 30/11/2025.
//

import SwiftUI

// Helper global pour vérifier l'existence des assets
func checkAssetExists(_ name: String) -> Bool {
    #if os(macOS)
    return NSImage(named: name) != nil
    #else
    return UIImage(named: name) != nil
    #endif
}

// MARK: - ENUMS

enum LeagueSubTab: String, CaseIterable {
    case overview = "Overview"
    case ranking = "Ranking"
    case fixtures = "Fixtures"
    case stats = "Stats"
    case history = "History"
}

enum OverviewSubTab: String, CaseIterable, Identifiable {
    case profile = "Profile"
    case seasonPreview = "Season Preview"
    case rules = "Rules"
    case finance = "Finance"
    
    var id: String { rawValue }
}

// MARK: - VUE PRINCIPALE

struct LeagueDetailsView: View {
    let competitionId: String
    let seasonId: String
    
    @State private var selectedSubTab: LeagueSubTab = .overview
    @State private var selectedOverviewSubTab: OverviewSubTab = .profile
    
    // Accès aux données via GameDatabase
    var competitionSeason: CompetitionSeason? {
        GameDatabase.shared.getCompetitionSeason(competitionId: competitionId, seasonId: seasonId)
    }
    
    var competition: Competition? {
        GameDatabase.shared.competitions.first(where: { $0.id == competitionId })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. BARRE D'ONGLETS
            HStack(spacing: 0) {
                ForEach(LeagueSubTab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .background(Color.black.opacity(0.6))
            
            // 2. CONTENU
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: "121212"))
    }
    
    // MARK: - BOUTONS D'ONGLETS
    
    @ViewBuilder
    private func tabButton(for tab: LeagueSubTab) -> some View {
        if tab == .overview {
            // Onglet Overview (Complexe avec Menu)
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Button(action: {
                        selectedSubTab = .overview
                        selectedOverviewSubTab = .profile
                    }) {
                        Text("OVERVIEW")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(selectedSubTab == tab ? .yellow : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Menu {
                        ForEach(OverviewSubTab.allCases) { sub in
                            Button(sub.rawValue) {
                                selectedSubTab = .overview
                                selectedOverviewSubTab = sub
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(selectedSubTab == tab ? .yellow : .gray)
                            .frame(width: 16, height: 16)
                            .contentShape(Rectangle())
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .menuIndicator(.hidden)
                }
                
                Rectangle()
                    .fill(selectedSubTab == tab ? Color.yellow : Color.clear)
                    .frame(height: 3)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 15)
            .background(Color.white.opacity(0.02))
        } else {
            // Autres Onglets (Simples)
            Button(action: { selectedSubTab = tab }) {
                VStack(spacing: 8) {
                    Text(tab.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(selectedSubTab == tab ? .yellow : .gray)
                    Rectangle()
                        .fill(selectedSubTab == tab ? Color.yellow : Color.clear)
                        .frame(height: 3)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 15)
                .background(Color.white.opacity(0.02))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - CONTENU PRINCIPAL
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            Color.clear
            if let season = competitionSeason {
                if season.status == .notScheduled && selectedSubTab != .history {
                    VStack(spacing: 15) {
                        Image(systemName: "calendar.badge.clock").font(.system(size: 50)).foregroundColor(.gray)
                        Text("Competition Not Scheduled Yet").font(.title3).bold().foregroundColor(.white)
                        Text("The draw for the upcoming season has not taken place.").foregroundColor(.gray)
                    }
                } else {
                    switch selectedSubTab {
                    case .overview:
                        switch selectedOverviewSubTab {
                        case .profile: LeagueOverviewView(competitionId: competitionId, seasonId: seasonId)
                        case .seasonPreview: Text("Season Preview Placeholder").foregroundColor(.gray)
                        case .rules: Text("Rules Placeholder").foregroundColor(.gray)
                        case .finance: Text("Financial Rules Placeholder").foregroundColor(.gray)
                        }
                    case .ranking:
                        LeagueRankingView(competitionId: competitionId, seasonId: seasonId)
                    case .fixtures:
                        LeagueFixturesView(competitionId: competitionId, seasonId: seasonId)
                    case .stats:
                        Text("Player Stats Placeholder").foregroundColor(.gray)
                        
                    case .history:
                        // MISE À JOUR ICI : Appel direct avec l'ID
                        // La vue CompetitionHistoryView gère maintenant la récupération depuis la sauvegarde
                        CompetitionHistoryView(competitionId: competitionId)
                    }
                }
            } else {
                Text("Season Data Not Found").foregroundColor(.red)
            }
        }
    }
}

// MARK: - SOUS-VUES

// 1. FIXTURES
struct LeagueFixturesView: View {
    let competitionId: String
    let seasonId: String
    @State private var currentDayIndex: Int = 0
    
    var allMatchDays: [MatchDay] {
        GameDatabase.shared.matchDays
            .filter { $0.competitionId == competitionId && $0.seasonId == seasonId }
            .sorted { $0.index < $1.index }
    }
    var currentMatchDay: MatchDay? {
        if allMatchDays.indices.contains(currentDayIndex) { return allMatchDays[currentDayIndex] }
        return nil
    }
    var currentMatches: [Match] {
        guard let md = currentMatchDay else { return [] }
        return GameDatabase.shared.matches.filter { $0.matchDayId == md.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { withAnimation { if currentDayIndex > 0 { currentDayIndex -= 1 } } }) {
                    Image(systemName: "chevron.left").font(.title2).foregroundColor(currentDayIndex > 0 ? .white : .gray.opacity(0.3)).padding()
                }.disabled(currentDayIndex == 0).buttonStyle(PlainButtonStyle())
                Spacer()
                if let md = currentMatchDay {
                    VStack(spacing: 4) {
                        Text(md.name.uppercased()).font(.headline).fontWeight(.black).foregroundColor(.white)
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                            Text(md.date.formatted(date: .complete, time: .omitted))
                        }.font(.caption).foregroundColor(.yellow)
                    }
                } else { Text("No Match Days") }
                Spacer()
                Button(action: { withAnimation { if currentDayIndex < allMatchDays.count - 1 { currentDayIndex += 1 } } }) {
                    Image(systemName: "chevron.right").font(.title2).foregroundColor(currentDayIndex < allMatchDays.count - 1 ? .white : .gray.opacity(0.3)).padding()
                }.disabled(currentDayIndex >= allMatchDays.count - 1).buttonStyle(PlainButtonStyle())
            }.background(Color.white.opacity(0.05))
            
            ScrollView {
                VStack(spacing: 8) {
                    if currentMatches.isEmpty {
                        Spacer(); Text("No matches scheduled for this day.").foregroundColor(.gray).padding(.top, 50); Spacer()
                    } else {
                        ForEach(currentMatches) { match in
                            MatchRowView(match: match, useAcronym: false, isCompact: true)
                        }
                    }
                }.padding()
            }
        }.onAppear {
            if let firstUnplayedIndex = allMatchDays.firstIndex(where: { !$0.isPlayed }) { currentDayIndex = firstUnplayedIndex }
            else if !allMatchDays.isEmpty { currentDayIndex = allMatchDays.count - 1 }
        }
    }
}

// 2. OVERVIEW
struct LeagueOverviewView: View {
    let competitionId: String
    let seasonId: String
    
    var competition: Competition? {
        GameDatabase.shared.competitions.first(where: { $0.id == competitionId })
    }
    var nextMatchDay: MatchDay? {
        GameDatabase.shared.matchDays
            .filter { $0.competitionId == competitionId && $0.seasonId == seasonId && !$0.isPlayed }
            .sorted { $0.date < $1.date }
            .first
    }
    var matches: [Match] {
        guard let md = nextMatchDay else { return [] }
        return GameDatabase.shared.matches.filter { $0.matchDayId == md.id }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // GAUCHE
            VStack(alignment: .leading, spacing: 15) {
                if let comp = competition, let winnerId = comp.titleHolderId {
                    LeagueTitleHolderView(competition: comp, clubId: winnerId)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("LEAGUE TABLE").font(.system(size: 9, weight: .medium)).foregroundColor(.gray).tracking(0.5).padding(.bottom, 5)
                    LeagueRankingView(competitionId: competitionId, seasonId: seasonId, isCompact: true)
                }
            }.frame(maxWidth: .infinity, alignment: .top)
            
            // DROITE
            VStack(alignment: .leading, spacing: 15) {
                if let comp = competition {
                    LeagueBroadcastersView(competition: comp)
                }
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("NEXT FIXTURES").font(.system(size: 9, weight: .medium)).foregroundColor(.gray).tracking(0.5)
                        Spacer()
                        if let md = nextMatchDay {
                            Text(md.label.uppercased()).font(.system(size: 9, weight: .bold)).foregroundColor(.yellow).tracking(0.5)
                        }
                    }.padding(.bottom, 10)
                    ScrollView {
                        VStack(spacing: 8) {
                            if matches.isEmpty {
                                Text("No upcoming matches scheduled").foregroundColor(.gray).italic()
                            } else {
                                ForEach(matches) { match in
                                    MatchRowView(match: match, useAcronym: true, isCompact: true)
                                }
                            }
                        }
                    }
                }
            }.frame(width: 450)
        }.padding()
    }
}

// 3. TITLE HOLDER
struct LeagueTitleHolderView: View {
    let competition: Competition
    let clubId: String
    var club: Club? { GameDatabase.shared.getClub(byId: clubId) }
    
    var body: some View {
        HStack(spacing: 12) {
            let trophyName = competition.trophyAssetName
            Image(trophyName).resizable().scaledToFit().frame(width: 35, height: 35).shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                .overlay { if !checkAssetExists(trophyName) { Image(systemName: "trophy.fill").font(.system(size: 20)).foregroundColor(.yellow.opacity(0.8)) } }
            VStack(alignment: .leading, spacing: 2) {
                Text("TITLE HOLDER").font(.system(size: 9, weight: .medium)).foregroundColor(.gray).tracking(0.5)
                HStack(spacing: 6) {
                    if let club = club {
                        ClubLogoView(clubId: club.id, size: 20)
                        Text(club.shortName).font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                    } else { Text("Unknown").font(.caption).foregroundColor(.gray) }
                }
            }
            Spacer()
        }.padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.01)]), startPoint: .leading, endPoint: .trailing)))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}

// 4. BROADCASTERS
struct LeagueBroadcastersView: View {
    let competition: Competition
    
    var body: some View {
        if !competition.safeBroadcasters.isEmpty {
            HStack(spacing: 12) {
                
                // 1. Icône TV
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                    Image(systemName: "tv.inset.filled")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .frame(width: 35, height: 35)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                
                // 2. Titre
                Text("DIFFUSION TV")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
                    .tracking(0.5)
                
                Spacer()
                
                // 3. Logos
                HStack(spacing: 8) {
                    ForEach(competition.safeBroadcasters, id: \.self) { broadcaster in
                        let assetName = "BROADCASTER-\(broadcaster)"
                        
                        if checkAssetExists(assetName) {
                            Image(assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .frame(maxWidth: 60)
                        } else {
                            Text(broadcaster)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.01)]), startPoint: .leading, endPoint: .trailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

// 6. CLASSEMENT


// 7. FORM BADGE
struct FormBadge: View {
    let result: String
    var color: Color { switch result { case "W": return .green; case "D": return .gray; case "L": return .red; default: return .gray.opacity(0.3) } }
    var resultText: String { switch result { case "W": return "V"; case "D": return "N"; case "L": return "D"; default: return "-" } }
    var body: some View {
        ZStack { Circle().fill(color).frame(width: 16, height: 16); Text(resultText).font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.7)) }
    }
}
