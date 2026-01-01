//
//  CompetitionDetailsView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 30/11/2025.
//

import SwiftUI

struct CompetitionDetailsView: View {
    let competitionId: String
    let seasonId: String
    
    var competition: Competition? {
        GameDatabase.shared.competitions.first(where: { $0.id == competitionId })
    }
    
    var body: some View {
        Group {
            if let comp = competition {
                if comp.type == .cup || comp.type == .superCup {
                    // ✅ Vue Spécifique COUPE
                    KnockOutCompetitionView(competitionId: competitionId, seasonId: seasonId)
                } else {
                    // ✅ Vue Spécifique CHAMPIONNAT
                    LeagueDetailsView(competitionId: competitionId, seasonId: seasonId)
                }
            } else {
                Text("Competition not found").foregroundColor(.gray)
            }
        }
    }
}
