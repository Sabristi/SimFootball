//
//  ClubScheduleView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 25/12/2025.
//

import SwiftUI

struct ClubScheduleView: View {
    let clubId: String
    let seasonId: String
    
    // État de sélection
    @State private var selectedMatchId: String?
    
    // --- 📏 CONSTANTES DE LARGEUR (POUR ALIGNEMENT PARFAIT) ---
    private let wDate: CGFloat = 80
    private let wTime: CGFloat = 50
    private let wVenue: CGFloat = 25
    private let wOpp: CGFloat = 140
    private let wRes: CGFloat = 30
    private let wScore: CGFloat = 60
    private let wComp: CGFloat = 120
    private let wInfo: CGFloat = 120 // Ajusté pour être cohérent
    
    // Récupérer et trier les matchs
    var clubMatches: [Match] {
        GameDatabase.shared.matches.filter {
            ($0.homeTeamId == clubId || $0.awayTeamId == clubId)
        }.sorted { ($0.kickoffTime ?? Date.distantFuture) < ($1.kickoffTime ?? Date.distantFuture) }
    }
    
    // Match sélectionné
    var selectedMatch: Match? {
        guard let id = selectedMatchId else { return nil }
        return clubMatches.first { $0.id == id }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            
            // ====================================================
            // COLONNE GAUCHE : TABLEAU (Liste des matchs)
            // ====================================================
            VStack(spacing: 0) {
                
                // 1. EN-TÊTE DU TABLEAU (Utilise les constantes)
                HStack(spacing: 0) {
                    HeaderCell(text: "DATE", width: wDate)
                    HeaderCell(text: "TIME", width: wTime)
                    HeaderCell(text: "", width: wVenue)
                    HeaderCell(text: "OPPOSITION", width: wOpp, alignment: .leading)
                    HeaderCell(text: "RES", width: wRes)
                    HeaderCell(text: "SCORE", width: wScore)
                    HeaderCell(text: "COMPETITION", width: wComp)
                    HeaderCell(text: "INFO", width: wInfo)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                
                // 2. LISTE DES MATCHS
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if clubMatches.isEmpty {
                                Text("No matches scheduled.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 50)
                            } else {
                                ForEach(clubMatches) { match in
                                    ScheduleRow(
                                        match: match,
                                        clubId: clubId,
                                        isSelected: selectedMatchId == match.id,
                                        isAlternate: false,
                                        // On passe les largeurs aux lignes pour garantir l'alignement
                                        widths: (wDate, wTime, wVenue, wOpp, wRes, wScore, wComp, wInfo)
                                    )
                                    .id(match.id)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            selectedMatchId = match.id
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .onAppear {
                        if selectedMatchId == nil {
                            // Sélectionner le premier match non joué ou le dernier joué
                            if let nextMatch = clubMatches.first(where: { $0.status == .scheduled || $0.status == .notScheduled }) {
                                selectedMatchId = nextMatch.id
                                DispatchQueue.main.async { proxy.scrollTo(nextMatch.id, anchor: .center) }
                            } else if let lastMatch = clubMatches.last {
                                selectedMatchId = lastMatch.id
                                DispatchQueue.main.async { proxy.scrollTo(lastMatch.id, anchor: .center) }
                            }
                        }
                    }
                }
            }
            .background(Color.black.opacity(0.2))
            .cornerRadius(12)
            
            // ====================================================
            // COLONNE DROITE : DÉTAIL MATCH
            // ====================================================
            VStack {
                if let match = selectedMatch {
                    MatchDetailPanel(match: match, clubId: clubId)
                        .id(match.id) // Force le rafraîchissement visuel
                        .transition(.opacity)
                } else {
                    Text("Select a match")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 350)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .padding(16)
        .background(Color(hex: "121212"))
    }
}

// MARK: - LIGNE DU TABLEAU (CORRIGÉE)

struct ScheduleRow: View {
    let match: Match
    let clubId: String
    let isSelected: Bool
    let isAlternate: Bool
    
    // Tuple pour recevoir les largeurs exactes
    let widths: (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
    
    // Données calculées
    var isHome: Bool { match.homeTeamId == clubId }
    var opponentId: String? { isHome ? match.awayTeamId : match.homeTeamId }
    var opponent: Club? { GameDatabase.shared.getClub(byId: opponentId ?? "") }
    
    var competition: Competition? {
        GameDatabase.shared.competitions.first(where: { $0.id == match.competitionId })
    }
    
    var matchDayName: String {
        let mdId = match.matchDayId
        if !mdId.isEmpty, let md = GameDatabase.shared.matchDays.first(where: { $0.id == mdId }) {
            return md.name
                .replacingOccurrences(of: "Journée ", with: "J")
                .replacingOccurrences(of: "Match Day ", with: "MD")
        }
        return "-"
    }
    
    var resultStatus: MatchResultStatus {
        guard match.status == .played,
              let h = match.homeTeamGoals,
              let a = match.awayTeamGoals else { return .pending }
        
        if h > a { return isHome ? .win : .loss }
        if a > h { return isHome ? .loss : .win }
        
        if let hPen = match.homePenalties, let aPen = match.awayPenalties {
            if hPen > aPen { return isHome ? .win : .loss }
            if aPen > hPen { return isHome ? .loss : .win }
        }
        return .draw
    }
    
    var body: some View {
        HStack(spacing: 0) {
            dateCell
            timeCell
            venueCell
            oppositionCell
            resultCell
            scoreCell
            competitionCell
            infoCell
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            isSelected ? Color.blue.opacity(0.3) :
            (isAlternate ? Color.white.opacity(0.03) : Color.clear)
        )
        .contentShape(Rectangle())
    }
    
    // --- CELLULES UTILISANT LES LARGEURS TRANSMISES ---
    
    private var dateCell: some View {
        Text(match.kickoffTime?.formatted(date: .numeric, time: .omitted) ?? "-")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.gray)
            .frame(width: widths.0, alignment: .leading)
    }
    
    private var timeCell: some View {
        Text(match.kickoffTime?.formatted(date: .omitted, time: .shortened) ?? "-")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white)
            .frame(width: widths.1, alignment: .leading)
    }
    
    private var venueCell: some View {
        Text(isHome ? "H" : "A")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(isHome ? .white : .yellow)
            .frame(width: widths.2, alignment: .center)
    }
    
    private var oppositionCell: some View {
        HStack(spacing: 6) {
            if let opp = opponent {
                ClubLogoView(clubId: opp.id, size: 20)
                Text(opp.shortName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            } else {
                Text(isHome ? match.awayTeamAlias : match.homeTeamAlias)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: widths.3, alignment: .leading)
        .padding(.leading, 4)
    }
    
    private var resultCell: some View {
        ZStack {
            if resultStatus != .pending {
                Circle().fill(resultStatus.color).frame(width: 14, height: 14)
                Text(resultStatus.label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
            } else {
                Text("-").font(.caption2).foregroundColor(.gray.opacity(0.3))
            }
        }
        .frame(width: widths.4, alignment: .center)
    }
    
    private var scoreCell: some View {
        Group {
            if match.status == .played {
                VStack(spacing: 0) {
                    let h = match.homeTeamGoals ?? 0
                    let a = match.awayTeamGoals ?? 0
                    let s = isHome ? "\(h)-\(a)" : "\(a)-\(h)"
                    Text(s).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    
                    if let hp = match.homePenalties, let ap = match.awayPenalties {
                        let p = isHome ? "(\(hp)-\(ap) p)" : "(\(ap)-\(hp) p)"
                        Text(p).font(.system(size: 8)).foregroundColor(.gray)
                    } else if match.wasExtraTimePlayed == true {
                        Text("a.p.").font(.system(size: 8)).foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 4).padding(.vertical, 2)
                .background(Color.white.opacity(0.1)).cornerRadius(4)
            } else {
                Text("vs").font(.system(size: 10)).foregroundColor(.gray)
            }
        }
        .frame(width: widths.5, alignment: .center)
    }
    
    private var competitionCell: some View {
        HStack(spacing: 6) {
            if let comp = competition {
                CompetitionLogoView(competitionId: comp.id, size: 18)
                Text(comp.shortName.prefix(15).uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray).lineLimit(1)
            } else {
                Text("-").font(.caption).foregroundColor(.gray)
            }
        }
        .frame(width: widths.6, alignment: .leading)
        .padding(.leading, 8)
    }
    
    private var infoCell: some View {
        Text(matchDayName)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.gray.opacity(0.7))
            .frame(width: widths.7, alignment: .trailing)
    }
}

// MARK: - PANNEAU DE DÉTAIL (DROITE)

// MARK: - PANNEAU DE DÉTAIL (DROITE)

struct MatchDetailPanel: View {
    let match: Match
    let clubId: String // On garde l'ID du club pour savoir si on met en gras notre équipe par exemple (optionnel)
    
    // Données liées
    var stadium: Stadium? { GameDatabase.shared.getStadium(byId: match.stadiumId ?? "") }
    
    // Récupération des deux clubs
    var homeClub: Club? { GameDatabase.shared.getClub(byId: match.homeTeamId ?? "") }
    var awayClub: Club? { GameDatabase.shared.getClub(byId: match.awayTeamId ?? "") }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. EN-TÊTE MATCH (Domicile vs Extérieur)
            VStack(spacing: 8) {
                Text(match.status == .played ? "FINAL SCORE" : "UPCOMING MATCH")
                    .font(.caption).fontWeight(.bold).foregroundColor(.gray).tracking(1)
                
                HStack(spacing: 15) {
                    
                    // --- ÉQUIPE DOMICILE (Gauche) ---
                    VStack {
                        if let club = homeClub {
                            ClubLogoView(clubId: club.id, size: 60)
                            Text(club.shortName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(club.id == clubId ? .yellow : .white) // Met en jaune si c'est nous
                                .multilineTextAlignment(.center)
                        } else {
                            // Cas générique (ex: Tirage pas fait)
                            Circle().fill(Color.gray.opacity(0.2)).frame(width: 60, height: 60)
                            Text(match.homeTeamAlias)
                                .font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                        }
                    }
                    .frame(width: 80) // Largeur fixe pour centrer
                    
                    // --- SCORE CENTRAL ---
                    VStack(spacing: 4) {
                        if match.status == .played {
                            // Score standard Domicile - Extérieur
                            Text("\(match.homeTeamGoals ?? 0) - \(match.awayTeamGoals ?? 0)")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.white)
                            
                            // Mentions a.p. / TAB
                            if let hp = match.homePenalties, let ap = match.awayPenalties {
                                Text("(\(hp)-\(ap) pen)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                            } else if match.wasExtraTimePlayed == true {
                                Text("A.E.T")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Text("VS")
                                .font(.title).fontWeight(.black)
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text(match.kickoffTime?.formatted(date: .omitted, time: .shortened) ?? "--:--")
                                .font(.caption).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .frame(width: 80)
                    
                    // --- ÉQUIPE EXTÉRIEUR (Droite) ---
                    VStack {
                        if let club = awayClub {
                            ClubLogoView(clubId: club.id, size: 60)
                            Text(club.shortName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(club.id == clubId ? .yellow : .white) // Met en jaune si c'est nous
                                .multilineTextAlignment(.center)
                        } else {
                            Circle().fill(Color.gray.opacity(0.2)).frame(width: 60, height: 60)
                            Text(match.awayTeamAlias)
                                .font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                        }
                    }
                    .frame(width: 80)
                }
            }
            .padding(.top, 20)
            
            Divider().background(Color.white.opacity(0.1))
            
            // 2. INFOS STADE & DÉTAILS
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(icon: "calendar", label: "Date", value: match.kickoffTime?.formatted(date: .complete, time: .omitted) ?? "TBD")
                
                DetailRow(icon: "sportscourt.fill", label: "Stadium", value: stadium?.name ?? "Unknown Stadium")
                
                // Calcul dynamique du lieu pour l'affichage
                let venueText = (match.homeTeamId == clubId) ? "Home Match" : "Away Match"
                DetailRow(icon: "map.fill", label: "Venue", value: venueText)
                
                if match.status == .played {
                    DetailRow(icon: "person.fill.whistle", label: "Referee", value: "Samir Guezzaz")
                    DetailRow(icon: "person.3.fill", label: "Attendance", value: "45,230")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Bouton Action
            if match.status != .played {
                Button(action: {}) {
                    Text("MATCH PREVIEW")
                        .font(.system(size: 10, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(20)
            }
        }
    }
}

// Helper Ligne Détail
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon).frame(width: 20).foregroundColor(.gray)
            Text(label).font(.system(size: 11)).foregroundColor(.gray)
            Spacer()
            Text(value).font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
        }
    }
}

// Cellule d'en-tête (Inchangée)
struct HeaderCell: View {
    let text: String
    var width: CGFloat? = nil
    var alignment: Alignment = .leading
    
    var body: some View {
        if let w = width {
            Text(text).font(.system(size: 9, weight: .bold)).foregroundColor(.gray).frame(width: w, alignment: alignment)
        } else {
            Text(text).font(.system(size: 9, weight: .bold)).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: alignment)
        }
    }
}

// Enum MatchResultStatus (Inchangé)
enum MatchResultStatus {
    case win, draw, loss, pending
    var color: Color {
        switch self {
        case .win: return .green
        case .draw: return .yellow
        case .loss: return .red
        case .pending: return .clear
        }
    }
    var label: String {
        switch self {
        case .win: return "V"
        case .draw: return "N"
        case .loss: return "D"
        case .pending: return ""
        }
    }
}
