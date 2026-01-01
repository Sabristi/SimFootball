//
//  ClubProfileView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 25/12/2025.
//

import SwiftUI

struct ClubProfileView: View {
    let club: Club
    
    // --- ACCÈS DONNÉES ---
    var stadium: Stadium? { GameDatabase.shared.getStadium(byId: club.stadiumId ?? "") }
    var city: City? { GameDatabase.shared.getCity(byId: club.cityId ?? "") }
    var country: Country? { GameDatabase.shared.getCountry(byId: club.countryId) }
    var league: Competition? { GameDatabase.shared.competitions.first(where: { $0.id == club.leagueId }) }
    
    // --- COULEURS ---
    var primaryColor: Color { Color(hex: "#" + club.identity.primaryColor) }
    var secondaryColor: Color { Color(hex: "#" + club.identity.secondaryColor) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // ====================================================
                // 1. EN-TÊTE INTÉGRÉ (INFO + KITS)
                // ====================================================
                ClubHeaderSection(
                    club: club,
                    country: country,
                    league: league,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor
                )
                
                // ====================================================
                // 2. CLUB ATMOSPHERE (PEOPLE)
                // ====================================================
                ClubAtmosphereSection()
                
                // ====================================================
                // 3. GRILLE : SAISON (G) vs INFRASTRUCTURES (D)
                // ====================================================
                HStack(alignment: .top, spacing: 16) {
                    
                    // --- COLONNE GAUCHE : SAISON EN COURS (Optimisée) ---
                    SeasonOverviewSection(league: league)
                    
                    // --- COLONNE DROITE : INFRASTRUCTURES ---
                    FacilitiesSection(
                        club: club,
                        stadium: stadium,
                        city: city
                    )
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .background(Color(hex: "121212"))
    }
}

// MARK: - SOUS-SECTIONS & COMPOSANTS

struct ClubHeaderSection: View {
    let club: Club
    let country: Country?
    let league: Competition?
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            
            // A. Identité (Gauche)
            HStack(spacing: 16) {
                ClubLogoView(clubId: club.id, size: 90)
                    .shadow(color: primaryColor.opacity(0.6), radius: 12, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(club.name.uppercased())
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let nickname = club.identity.nickname {
                        Text("“\(nickname)”")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .italic()
                            .foregroundColor(.gray)
                    }
                    
                    // Badges Pays & Division
                    HStack(spacing: 10) {
                        if let c = country {
                            HStack(spacing: 6) {
                                Text(c.flagEmoji).font(.headline)
                                Text(c.name.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.white.opacity(0.1)).cornerRadius(6)
                        }
                        
                        if let l = league {
                            HStack(spacing: 6) {
                                CompetitionLogoView(competitionId: l.id, size: 18)
                                Text(l.name.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.white.opacity(0.1)).cornerRadius(6)
                        }
                    }
                    .padding(.top, 6)
                }
            }
            
            Spacer()
            
            // B. Maillots (Droite)
            HStack(spacing: 15) {
                if let homeKit = club.kits.first(where: { $0.type == .home }) {
                    KitHeaderPreview(kit: homeKit, label: "HOME")
                }
                if let awayKit = club.kits.first(where: { $0.type == .away }) {
                    KitHeaderPreview(kit: awayKit, label: "AWAY")
                }
                if let thirdKit = club.kits.first(where: { $0.type == .third }) {
                    KitHeaderPreview(kit: thirdKit, label: "3RD")
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.25))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
        }
        .padding(24)
        .background(
            ZStack {
                primaryColor.opacity(0.15)
                LinearGradient(colors: [primaryColor.opacity(0.4), .black.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// 2. ATMOSPHÈRE
struct ClubAtmosphereSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            SectionHeader(title: "PEOPLE", icon: "person.3.sequence.fill")
            
            HStack(spacing: 0) {
                StaffCell(role: "PRESIDENT", name: "Aziz El Badraoui", mood: "Satisfied", color: .green)
                Divider().background(Color.white.opacity(0.1))
                StaffCell(role: "MANAGER", name: "You", mood: "Secure", color: .blue)
                Divider().background(Color.white.opacity(0.1))
                StaffCell(role: "SUPPORTERS", name: "Ultras", mood: "Ecstatic", color: .yellow)
            }
            .frame(height: 50)
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}

// 3. SAISON (Gauche - Optimisée pour hauteur 320)
struct SeasonOverviewSection: View {
    let league: Competition?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            SectionHeader(title: "CURRENT SEASON", icon: "chart.bar.fill")
                // On garde un padding fixe en bas du titre pour ne pas qu'il colle
                .padding(.bottom, 10)
            
            // CONTENU
            // On utilise un VStack où chaque élément prend le max de place possible
            // pour s'équilibrer parfaitement.
            VStack(spacing: 0) {
                
                // 1. Championnat
                VStack {
                    Spacer()
                    SeasonRow(
                        name: league?.shortName ?? "League",
                        logoId: league?.id,
                        rank: "3rd",
                        detail: "45 Pts",
                        color: .green
                    )
                    Spacer()
                }
                .frame(maxHeight: .infinity) // Prend 1/3 de la hauteur dispo
                
                Divider().background(Color.white.opacity(0.05))
                
                // 2. Coupe
                VStack {
                    Spacer()
                    SeasonRow(
                        name: "Coupe du Trône",
                        logoId: "COMP-MAR-CT",
                        rank: "Semi Final",
                        detail: "vs AS FAR",
                        color: .orange
                    )
                    Spacer()
                }
                .frame(maxHeight: .infinity) // Prend 1/3 de la hauteur dispo
                
                Divider().background(Color.white.opacity(0.05))
                
                // 3. Continental
                VStack {
                    Spacer()
                    SeasonRow(
                        name: "CAF Champions League",
                        logoId: "COMP-CAF-CL",
                        rank: "Group St.",
                        detail: "2nd (Gr A)",
                        color: .blue
                    )
                    Spacer()
                }
                .frame(maxHeight: .infinity) // Prend 1/3 de la hauteur dispo
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 320) // Hauteur conservée
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// --- LIGNE DE SAISON (Centrée Horizontalement) ---
struct SeasonRow: View {
    let name: String
    let logoId: String?
    let rank: String
    let detail: String
    let color: Color
    
    var body: some View {
        // On retire le Spacer() à la fin pour que le contenu se centre
        HStack(spacing: 12) {
            
            // LOGO
            if let lid = logoId {
                CompetitionLogoView(competitionId: lid, size: 32)
            } else {
                Circle().fill(Color.gray.opacity(0.2)).frame(width: 32, height: 32)
            }
            
            // TEXTES
            VStack(alignment: .leading, spacing: 3) {
                Text(name.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(rank)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(color)
                    
                    Text("• " + detail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        // ✅ Cette frame force le HStack à se centrer dans le parent
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 2)
    }
}

// 4. INFRASTRUCTURES (Droite)
struct FacilitiesSection: View {
    let club: Club
    let stadium: Stadium?
    let city: City?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "FACILITIES", icon: "building.2.fill")
                .padding(.bottom, 12)
            
            // Image Stade
            ZStack(alignment: .bottomLeading) {
                if checkAssetExists(club.stadiumId ?? "") {
                    Image(club.stadiumId ?? "")
                        .resizable().scaledToFill()
                } else {
                    Image("stadium_placeholder")
                        .resizable().scaledToFill()
                        .overlay(Color.black.opacity(0.4))
                }
            }
            .frame(height: 230) // ✅ TAILLE CONSERVÉE
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(8)
            .overlay(
                // Nom du stade sur l'image
                VStack(alignment: .leading, spacing: 2) {
                    Spacer()
                    Text(stadium?.name ?? "Unknown Stadium")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 3)
                    
                    Text("\(stadium?.capacity ?? 0) Seats")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                        .shadow(color: .black, radius: 3)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
            )
            
            Spacer()
            
            // Infos Ville / Fondation
            HStack(spacing: 10) {
                FacilityInfoRow(icon: "map.fill", title: "CITY", value: city?.name ?? "-")
                Spacer()
                FacilityInfoRow(icon: "calendar", title: "EST.", value: "\(club.foundedYear)")
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 320) // ✅ TAILLE CONSERVÉE
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - COMPOSANTS UI DE BASE

// Aperçu Mini Kit (Header)
struct KitHeaderPreview: View {
    let kit: Kit
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            KitRendererView(kit: kit)
                // ✅ RÉGLAGE TAILLE MAILLOTS ICI
                .frame(width: 65, height: 75)
                .shadow(radius: 3)
            
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.gray)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.yellow)
            Text(title).font(.footnote).fontWeight(.black).foregroundColor(.gray).tracking(1)
            Spacer()
        }
    }
}

struct StaffCell: View {
    let role: String, name: String, mood: String, color: Color
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(role).font(.system(size: 8, weight: .bold)).foregroundColor(.gray).tracking(0.5)
            Text(name).font(.system(size: 11, weight: .bold)).foregroundColor(.white).lineLimit(1)
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 5, height: 5)
                Text(mood).font(.system(size: 9)).foregroundColor(color)
            }
        }.frame(maxWidth: .infinity)
    }
}

struct FacilityInfoRow: View {
    let icon: String, title: String, value: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2).foregroundColor(.gray)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.system(size: 7, weight: .bold)).foregroundColor(.gray)
                Text(value).font(.system(size: 10, weight: .bold)).foregroundColor(.white)
            }
        }
    }
}
