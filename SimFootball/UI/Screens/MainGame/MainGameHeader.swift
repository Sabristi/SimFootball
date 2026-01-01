//
//  MainGameHeader.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 26/11/2025.
//

import SwiftUI

struct MainGameHeader: View {
    // Données principales
    let title: String
    var subtitle: String? = nil
    
    // Contexte visuel
    let icon: String
    var competitionId: String? = nil
    var country: Country? = nil
    
    // --- NAVIGATION CLUB ---
    var showClubNavigation: Bool = false
    var onClubNavigation: ((Int) -> Void)? = nil // Int: -1 (Haut/Précédent), +1 (Bas/Suivant)
    
    // Données temporelles & Actions
    let currentDate: Date
    let onBack: () -> Void
    let onContinue: () -> Void
    let onCalendarClick: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            
            // 1. BOUTON RETOUR
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // 2. SÉPARATEUR VERTICAL
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 30)
            
            // 3. IDENTITÉ (Logo + Navigation + Titre)
            HStack(spacing: 12) {
                
                // A. LOGO DYNAMIQUE
                Group {
                    if let compId = competitionId {
                        CompetitionLogoView(competitionId: compId, size: 40)
                    } else if let c = country {
                        Text(c.flagEmoji).font(.system(size: 36))
                    } else {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(.green)
                            .frame(width: 40, height: 40)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // B. FLÈCHES DE NAVIGATION (Placées ici, entre le logo et le titre)
                if showClubNavigation {
                    VStack(spacing: 2) {
                        // Flèche HAUT (Club précédent / rang supérieur)
                        Button(action: { onClubNavigation?(-1) }) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 24, height: 12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Flèche BAS (Club suivant / rang inférieur)
                        Button(action: { onClubNavigation?(1) }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 24, height: 12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // C. TEXTES (Titre + Sous-titre)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    if let sub = subtitle {
                        Text(sub)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Spacer()
            
            // 4. DATE & CALENDRIER
            Button(action: onCalendarClick) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.green)
                    Text(currentDate.formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())
            
            // 5. BOUTON CONTINUE
            Button(action: onContinue) {
                HStack {
                    Text("CONTINUE")
                        .fontWeight(.black)
                    Image(systemName: "play.fill")
                }
                .font(.subheadline)
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.green)
                .cornerRadius(20)
                .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: "121212"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.1)), alignment: .bottom)
    }
}
