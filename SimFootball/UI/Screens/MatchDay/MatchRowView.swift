//
//  MatchRowView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 24/12/2025.
//

import SwiftUI

struct MatchRowView: View {
    let match: Match
    var useAcronym: Bool = false
    var isCompact: Bool = false
    
    // MARK: - Helpers Contextuels
    
    // On récupère la compétition du match pour savoir comment l'afficher
    private var competition: Competition? {
        GameDatabase.shared.competitions.first(where: { $0.id == match.competitionId })
    }
    
    private var displayMode: RowDisplayMode? {
        return competition?.displayRow
    }
    
    // MARK: - Helpers Données
    
    var homeClub: Club? { GameDatabase.shared.getClub(byId: match.homeTeamId ?? "") }
    var awayClub: Club? { GameDatabase.shared.getClub(byId: match.awayTeamId ?? "") }
    
    var homeName: String {
        return useAcronym ? (homeClub?.acronym ?? homeClub?.shortName ?? match.homeTeamAlias) : (homeClub?.shortName ?? match.homeTeamAlias)
    }
    
    var awayName: String {
        return useAcronym ? (awayClub?.acronym ?? awayClub?.shortName ?? match.awayTeamAlias) : (awayClub?.shortName ?? match.awayTeamAlias)
    }
    
    // Génère le texte de l'indicateur (Position, Division, ou Drapeau)
    func getIndicatorText(for club: Club?, teamId: String?, isHome: Bool) -> String? {
        guard let mode = displayMode else { return nil }
        
        switch mode {
        case .showPositions:
            // Récupère la position dans le classement
            guard let tableId = match.tableId, let tId = teamId else { return nil }
            if let pos = GameDatabase.shared.getTeamPosition(teamId: tId, tableId: tableId) {
                // ✅ Formatage : "1er", "2e", "3e"...
                return pos == 1 ? "1er" : "\(pos)e"
            }
            
        case .showDivisions:
            // Récupère l'acronyme de la compétition du club
            guard let club = club else { return nil }
            if let comp = GameDatabase.shared.competitions.first(where: { $0.id == club.leagueId }) {
                return comp.acronym ?? comp.shortName.prefix(3).uppercased()
            }
            
        case .showFlags:
            // Récupère le drapeau du pays
            guard let club = club else { return nil }
            if let country = GameDatabase.shared.getCountry(byId: club.countryId) {
                return country.flagEmoji // Affiche le drapeau 🇲🇦
            }
        }
        
        return nil
    }
    
    // ✅ Helper pour gérer la taille de police dynamiquement
    var indicatorFontSize: CGFloat {
        // Plus gros (18) pour les drapeaux, petit (9) pour le texte
        return displayMode == .showFlags ? 18 : 9
    }
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 0) {
            
            // --- GAUCHE : ÉQUIPE DOMICILE ---
            HStack(spacing: 8) {
                
                // INDICATEUR GAUCHE
                if let indicator = getIndicatorText(for: homeClub, teamId: match.homeTeamId, isHome: true) {
                    Text(indicator)
                        .font(.system(size: indicatorFontSize, weight: .bold)) // ✅ Taille ajustée
                        .foregroundColor(displayMode == .showFlags ? .primary : .gray.opacity(0.8))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // NOM (CLIQUABLE)
                TeamLinkView(teamId: match.homeTeamId) {
                    Text(homeName)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(isWinner(isHome: true) ? .white : .gray)
                }
                
                // LOGO (CLIQUABLE AUSSI)
                TeamLinkView(teamId: match.homeTeamId) {
                    if let id = match.homeTeamId { ClubLogoView(clubId: id, size: 28) }
                    else { Circle().fill(Color.gray.opacity(0.3)).frame(width: 28, height: 28) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // --- CENTRE : SCORE ---
            ZStack {
                if match.status == .played || match.status == .live {
                    VStack(spacing: 2) {
                        Text("\(match.homeTeamGoals ?? 0) - \(match.awayTeamGoals ?? 0)")
                            .fontWeight(.black)
                            .foregroundColor(.yellow)
                            .font(.title3)
                        
                        if let agg = getAggregateString() {
                            Text(agg)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        if let hp = match.homePenalties, let ap = match.awayPenalties {
                            Text("(\(hp)-\(ap) tab)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                        } else if match.wasExtraTimePlayed ?? false {
                            Text("a.p.")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                        }
                    }
                }
                else if match.status == .postponed {
                    Text("REP")
                        .font(.caption).fontWeight(.bold).foregroundColor(.orange)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.orange, lineWidth: 1))
                }
                else {
                    VStack(spacing: 2) {
                        Text("vs")
                            .font(.caption).fontWeight(.bold).foregroundColor(.gray.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(4)
                        
                        if let leg1Score = getFirstLegScoreString() {
                            Text(leg1Score)
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(width: 80)
            
            // --- DROITE : ÉQUIPE EXTÉRIEUR ---
            HStack(spacing: 8) {
                // LOGO (CLIQUABLE)
                TeamLinkView(teamId: match.awayTeamId) {
                    if let id = match.awayTeamId { ClubLogoView(clubId: id, size: 28) }
                    else { Circle().fill(Color.gray.opacity(0.3)).frame(width: 28, height: 28) }
                }
                
                // NOM (CLIQUABLE)
                TeamLinkView(teamId: match.awayTeamId) {
                    Text(awayName)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(isWinner(isHome: false) ? .white : .gray)
                }
                
                Spacer()
                
                // INDICATEUR DROIT
                if let indicator = getIndicatorText(for: awayClub, teamId: match.awayTeamId, isHome: false) {
                    Text(indicator)
                        .font(.system(size: indicatorFontSize, weight: .bold)) // ✅ Taille ajustée
                        .foregroundColor(displayMode == .showFlags ? .primary : .gray.opacity(0.8))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, isCompact ? 6 : 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .foregroundColor(.white)
    }
    
    // MARK: - Logique Aggregat & Vainqueur (Inchangée)
    
    private func getFirstLegMatch() -> Match? {
        guard match.type == .secondLeg, let leg1Id = match.firstLegMatchId else { return nil }
        return GameDatabase.shared.matches.first(where: { $0.id == leg1Id })
    }
    
    private func getAggregateString() -> String? {
        guard let leg1 = getFirstLegMatch(), match.status == .played else { return nil }
        let hGoals = match.homeTeamGoals ?? 0
        let aGoals = match.awayTeamGoals ?? 0
        var leg1HomeGoalsForCurrentHome = 0
        var leg1AwayGoalsForCurrentAway = 0
        if leg1.homeTeamId == match.homeTeamId { leg1HomeGoalsForCurrentHome = leg1.homeTeamGoals ?? 0 }
        else if leg1.awayTeamId == match.homeTeamId { leg1HomeGoalsForCurrentHome = leg1.awayTeamGoals ?? 0 }
        if leg1.homeTeamId == match.awayTeamId { leg1AwayGoalsForCurrentAway = leg1.homeTeamGoals ?? 0 }
        else if leg1.awayTeamId == match.awayTeamId { leg1AwayGoalsForCurrentAway = leg1.awayTeamGoals ?? 0 }
        let aggHome = hGoals + leg1HomeGoalsForCurrentHome
        let aggAway = aGoals + leg1AwayGoalsForCurrentAway
        return "agg. \(aggHome)-\(aggAway)"
    }
    
    private func getFirstLegScoreString() -> String? {
        guard let leg1 = getFirstLegMatch() else { return nil }
        guard let h = leg1.homeTeamGoals, let a = leg1.awayTeamGoals else { return nil }
        if leg1.awayTeamId == match.homeTeamId { return "(\(a)-\(h))" }
        else { return "(\(h)-\(a))" }
    }
    
    private func isWinner(isHome: Bool) -> Bool {
        guard match.status == .played else { return true }
        if match.type == .knockoutSingle || match.type == .secondLeg {
            if let hp = match.homePenalties, let ap = match.awayPenalties { return isHome ? hp > ap : ap > hp }
            if match.type == .secondLeg, let aggStr = getAggregateString() {
                let components = aggStr.replacingOccurrences(of: "agg. ", with: "").split(separator: "-")
                if components.count == 2, let hAgg = Int(components[0]), let aAgg = Int(components[1]) {
                    if hAgg != aAgg { return isHome ? hAgg > aAgg : aAgg > hAgg }
                }
            }
        }
        guard let h = match.homeTeamGoals, let a = match.awayTeamGoals else { return true }
        if h == a { return true }
        return isHome ? h > a : a > h
    }
}
