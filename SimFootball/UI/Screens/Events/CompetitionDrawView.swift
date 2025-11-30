import SwiftUI

struct CompetitionDrawView: View {
    let competitionId: String
    let seasonId: String // ID de la saison en cours (ex: "S_2025_26")
    let onClose: () -> Void
    let onComplete: () -> Void // Callback quand le tirage est fini
    
    @State private var participants: [Club] = []
    @State private var isProcessing: Bool = false
    @State private var drawCompleted: Bool = false
    
    // État pour gérer le chargement initial des données
    @State private var isLoadingData: Bool = true
    
    var body: some View {
        ZStack {
            // 1. FOND FLOU (Overlay sombre)
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { if !isProcessing { onClose() } }
            
            // 2. LA FENÊTRE POPUP
            VStack(spacing: 0) {
                
                // HEADER
                HStack {
                    Image(systemName: "trophy.circle.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                    
                    Text("TIRAGE AU SORT : BOTOLA PRO")
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .disabled(isProcessing)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                
                // CONTENU
                VStack(spacing: 20) {
                    
                    // Affichage joli de la saison (ex: "2025/2026")
                    let seasonLabel = seasonId
                        .replacingOccurrences(of: "S_", with: "")
                        .replacingOccurrences(of: "_", with: "/")
                    
                    Text("Participants Saison \(seasonLabel)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 10)
                    
                    // --- GRILLE DES CLUBS (Gérée proprement) ---
                    if isLoadingData {
                        // Cas 1 : Chargement en cours
                        VStack(spacing: 15) {
                            ProgressView()
                                .tint(.yellow)
                            Text("Chargement des participants...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(height: 200)
                        
                    } else if participants.isEmpty {
                        // Cas 2 : Erreur / Pas de données
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Aucun participant trouvé.")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Vérifiez la configuration de la saison.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(height: 200)
                        
                    } else {
                        // Cas 3 : Données chargées
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(participants) { club in
                                    HStack {
                                        // Pastille couleur club
                                        Circle()
                                            .fill(Color(hex: club.identity.primaryColor))
                                            .frame(width: 12, height: 12)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                        
                                        Text(club.name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 300) // Hauteur max de la liste
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // BOUTON D'ACTION
                    if drawCompleted {
                        VStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                            Text("Calendrier Généré !")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .transition(.scale)
                    } else {
                        Button(action: startDrawProcess) {
                            HStack {
                                if isProcessing {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "shuffle")
                                }
                                Text(isProcessing ? "GÉNÉRATION EN COURS..." : "GÉNÉRER LE CALENDRIER")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(participants.isEmpty ? Color.gray : Color.yellow) // Grisé si pas de participants
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .shadow(color: .yellow.opacity(0.3), radius: 10)
                        }
                        .disabled(isProcessing || participants.isEmpty) // Empêche le clic si vide
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .frame(width: 550) // Largeur fixe style "Fenêtre"
            .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(radius: 20)
        }
        .onAppear {
            loadData()
        }
    }
    
    // --- LOGIQUE INTERNE ---
    
    func loadData() {
        self.isLoadingData = true // Début du chargement
        
        // Petit délai simulé pour l'effet UI et laisser le temps à la DB de s'initialiser si besoin
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if competitionId == "COMP-MAR-BP1" {
                // Appel Dynamique au service
                self.participants = BotolaPro1DrawService.shared.getParticipants(seasonId: seasonId)
            } else {
                print("⚠️ Pas de service de tirage configuré pour \(competitionId)")
            }
            
            // Fin du chargement (avec ou sans résultats)
            withAnimation {
                self.isLoadingData = false
            }
        }
    }
    
    func startDrawProcess() {
        withAnimation { isProcessing = true }
        
        // Simulation d'attente (Suspense...)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Appel au service pour effectuer le tirage
            let success = BotolaPro1DrawService.shared.performDraw()
            
            if success {
                withAnimation {
                    isProcessing = false
                    drawCompleted = true
                }
                
                // Fermeture auto et validation de l'event après 1.5s
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onComplete()
                }
            } else {
                print("❌ Échec du tirage")
                isProcessing = false
            }
        }
    }
}
