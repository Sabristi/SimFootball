import SwiftUI
import Combine

// Modèle temporaire pour l'affichage dans la vue (ne va pas en base de données)
struct CupPairing: Identifiable {
    let id = UUID()
    var homeTeam: Club?
    var awayTeam: Club?
    var matchLabel: String // "Match 1", "Match 2"...
    
    var isComplete: Bool { homeTeam != nil && awayTeam != nil }
}

class CupDrawViewModel: ObservableObject {
    
    // --- ÉTAT UI ---
    @Published var pot: [Club] = []            // Les équipes encore dans le saladier
    @Published var drawnPairs: [CupPairing] = [] // Les paires formées
    @Published var currentPair: CupPairing?    // La paire en cours de construction
    @Published var lastDrawnTeam: Club?        // Pour l'animation "Carte retournée"
    @Published var isFinished: Bool = false
    
    // --- CONTEXTE ---
    let roundId: String   // Ex: "R32"
    let seasonId: String  // Ex: "S_2025_26"
    private let competitionId = "COMP-MAR-CT"
    
    init(roundId: String, seasonId: String) {
        self.roundId = roundId
        self.seasonId = seasonId
    }
    
    // 1. CHARGEMENT DES ÉQUIPES (NETTOYÉ & OPTIMISÉ)
    func loadQualifiedTeams() {
        print("🔍 [CupDraw] Chargement des participants via le Service pour : \(roundId)...")
        
        // ✅ ON DÉLÈGUE TOUT AU SERVICE (Plus de logique R32/R16 ici)
        // Le service sait déjà comment récupérer les équipes (BP1/BP2 ou Vainqueurs précédents)
        let qualifiedIds = CompetitionDrawService.shared.getQualifiedTeamsForCup(roundId: roundId)
        
        // Conversion des IDs en Objets Club
        let clubs = qualifiedIds.compactMap { GameDatabase.shared.getClub(byId: $0) }
        
        if clubs.isEmpty {
            print("⚠️ Aucun qualifié trouvé. Vérifiez que les matchs du tour précédent sont bien marqués 'Played'.")
        } else {
            self.pot = clubs.shuffled() // On mélange
            print("✅ [CupDraw] \(pot.count) équipes placées dans le saladier.")
        }
    }
    
    // 2. ACTION : TIRER UNE BOULE
    func drawNextBall() {
        guard !pot.isEmpty else { return }
        
        // On tire une équipe
        let team = pot.removeLast()
        
        // Animation
        withAnimation(.spring()) {
            self.lastDrawnTeam = team
        }
        
        // Logique d'appariement
        if var activePair = currentPair {
            // C'est l'équipe EXTÉRIEUR
            activePair.awayTeam = team
            
            withAnimation {
                self.drawnPairs.append(activePair)
                self.currentPair = nil
            }
            
            if pot.isEmpty { isFinished = true }
            
        } else {
            // C'est l'équipe DOMICILE
            let matchNumber = drawnPairs.count + 1
            let newPair = CupPairing(homeTeam: team, awayTeam: nil, matchLabel: "Match \(matchNumber)")
            
            withAnimation {
                self.currentPair = newPair
            }
        }
    }
    
    // 3. ACTION : SIMULER LE RESTE
    func simulateRemaining() {
        while !pot.isEmpty {
            drawNextBall()
        }
    }
    
    // 4. ACTION : VALIDER ET SAUVEGARDER
    func confirmDrawAndSave(dismissAction: @escaping () -> Void) {
            var matchesToSave: [Match] = []
            
            // --- 1. CONFIGURATION DU FORMAT ---
            // Est-ce un tour Aller-Retour ? (QF et SF)
            let isTwoLegged = roundId.contains("QF") || roundId.contains("SF")
            
            // --- 2. CRÉATION DES MATCHS ---
            for (index, pair) in drawnPairs.enumerated() {
                guard let home = pair.homeTeam, let away = pair.awayTeam else { continue }
                
                // --- MATCH ALLER (Ou match unique) ---
                let leg1Id = UUID().uuidString
                // Pour l'aller, on joue chez le premier tiré (home)
                let matchDayId1 = getMatchDayId(leg: 1)
                let date1 = GameDatabase.shared.matchDays.first { $0.id == matchDayId1 }?.date
                
                let match1 = Match(
                    id: leg1Id,
                    competitionId: competitionId,
                    matchDayId: matchDayId1,
                    homeTeamAlias: "CUP_\(roundId)_M\(index+1)_L1_H",
                    awayTeamAlias: "CUP_\(roundId)_M\(index+1)_L1_A",
                    homeTeamId: home.id,
                    awayTeamId: away.id,
                    stadiumId: home.stadiumId,
                    kickoffTime: date1,
                    status: .scheduled,
                    // Si c'est Aller-Retour, le match 1 est "FirstLeg", sinon "KnockoutSingle"
                    type: isTwoLegged ? .firstLeg : .knockoutSingle,
                    firstLegMatchId: nil
                )
                matchesToSave.append(match1)
                
                // --- MATCH RETOUR (Si nécessaire) ---
                if isTwoLegged {
                    let leg2Id = UUID().uuidString
                    // Pour le retour, on inverse : 'away' reçoit 'home'
                    let matchDayId2 = getMatchDayId(leg: 2)
                    let date2 = GameDatabase.shared.matchDays.first { $0.id == matchDayId2 }?.date
                    
                    let match2 = Match(
                        id: leg2Id,
                        competitionId: competitionId,
                        matchDayId: matchDayId2,
                        homeTeamAlias: "CUP_\(roundId)_M\(index+1)_L2_H", // Alias inversés implicitement par les IDs
                        awayTeamAlias: "CUP_\(roundId)_M\(index+1)_L2_A",
                        homeTeamId: away.id, // L'équipe B reçoit au retour
                        awayTeamId: home.id, // L'équipe A se déplace
                        stadiumId: away.stadiumId,
                        kickoffTime: date2,
                        status: .scheduled,
                        type: .secondLeg, // C'est ici que la magie opère
                        firstLegMatchId: leg1Id // Lien vers le match aller
                    )
                    matchesToSave.append(match2)
                }
            }
            
            // Sauvegarde
            GameDatabase.shared.matches.append(contentsOf: matchesToSave)
            GameDatabase.shared.saveMatches()
            
            // Mise à jour Statut
            updateCompetitionStatus()
            
            print("✅ Tirage terminé : \(matchesToSave.count) matchs créés (Aller-Retour: \(isTwoLegged)).")
            dismissAction()
    }
        
    // Helper pour récupérer l'ID du MatchDay (Aller ou Retour)
    private func getMatchDayId(leg: Int = 1) -> String {
            if roundId.contains("R32") { return "MD-CT-R32" }
            if roundId.contains("R16") { return "MD-CT-R16" }
            
            // Pour les tours à deux manches
            if roundId.contains("QF") {
                return leg == 1 ? "MD-CT-QF-1" : "MD-CT-QF-2"
            }
            if roundId.contains("SF") {
                return leg == 1 ? "MD-CT-SF-1" : "MD-CT-SF-2" // Assurez-vous d'avoir créé ces MD dans MatchDays.json !
            }
            
            if roundId.contains("FINAL") { return "MD-CT-FINAL" }
            return "MD-CT-GEN"
    }
    
    private func updateCompetitionStatus() {
        if let index = GameDatabase.shared.competitionSeasons.firstIndex(where: { $0.competitionId == competitionId && $0.seasonId == seasonId }) {
            
            var compSeason = GameDatabase.shared.competitionSeasons[index]
            compSeason.status = .planned // ou .ongoing selon votre enum
            
            // On peut mettre à jour les participants si on veut garder une trace
            // Mais pour une coupe c'est moins critique car ça change tout le temps
            
            GameDatabase.shared.competitionSeasons[index] = compSeason
            GameDatabase.shared.saveCompetitionSeasons()
        }
    }
    
    private func getMatchDayId() -> String {
        // Mapping simple (Assurez-vous que ces IDs existent dans MatchDays.json)
        if roundId.contains("R32") { return "MD-CT-R32" }
        if roundId.contains("R16") { return "MD-CT-R16" }
        if roundId.contains("QF") { return "MD-CT-QF-1" }
        if roundId.contains("SF") { return "MD-CT-SF-1" }
        if roundId.contains("FINAL") { return "MD-CT-FINAL" }
        return "MD-CT-GEN"
    }
}
