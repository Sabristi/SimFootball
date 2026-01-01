import SwiftUI

struct NewGameSetupView: View {
    let slotId: Int
    
    @State private var selectedSlotIdForNewGame: Int? = nil
    @State private var selectedMode: GameMode? = nil
    
    // MODIF : Array pour l'ordre
    @State private var selectedCountries: [Country] = []
    
    @State private var navigateToGame: Bool = false
    @State private var createdGameState: GameState?
    
    var availableCountries: [Country] {
        return GameDatabase.shared.countries
            .filter { $0.isPlayable }
            .sorted { $0.name < $1.name }
    }
    
    var isValid: Bool {
        return selectedMode != nil &&
               !selectedCountries.isEmpty &&
               selectedCountries.count <= 5
    }
    
    var body: some View {
        HStack(spacing: 0) {
            
            // --- COLONNE GAUCHE : MODE ---
            VStack(alignment: .leading, spacing: 20) {
                Text("1. CHOOSE YOUR PATH")
                    .font(.headline).foregroundColor(.gray).tracking(2)
                
                ForEach(GameMode.allCases) { mode in
                    Button(action: { selectedMode = mode }) {
                        HStack(spacing: 15) {
                            Image(systemName: mode.icon)
                                .font(.title2)
                                .foregroundColor(selectedMode == mode ? .black : .white)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(mode.rawValue).fontWeight(.bold)
                                Text(mode.description).font(.caption).opacity(0.7)
                            }
                            Spacer()
                            if selectedMode == mode {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.black)
                            }
                        }
                        .padding()
                        .background(selectedMode == mode ? Color.green : Color.white.opacity(0.05))
                        .foregroundColor(selectedMode == mode ? .black : .white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer()
            }
            .padding(40)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.8))
            
            // --- COLONNE DROITE : PAYS ---
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("2. SELECT NATIONS")
                        .font(.headline).foregroundColor(.gray).tracking(2)
                    Spacer()
                    
                    // Indicateur Primary
                    if let primary = selectedCountries.first {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").font(.caption).foregroundColor(.yellow)
                            Text("Primary: \(primary.name)")
                        }
                        .font(.caption).fontWeight(.bold).foregroundColor(.yellow)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.yellow.opacity(0.1)).cornerRadius(8)
                        .padding(.trailing, 10)
                    }
                    
                    Text("\(selectedCountries.count)/5 Selected")
                        .font(.caption).fontWeight(.bold)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(selectedCountries.count > 5 ? Color.red : Color.green.opacity(0.2))
                        .foregroundColor(selectedCountries.count > 5 ? .white : .green)
                        .cornerRadius(8)
                }
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(availableCountries) { country in
                            // Détection de l'état de sélection
                            let isSelected = selectedCountries.contains(country)
                            let isPrimary = selectedCountries.first == country
                            
                            Button(action: { toggleCountry(country) }) {
                                HStack {
                                    Text(country.flagEmoji)
                                    Text(country.name).fontWeight(.semibold)
                                    Spacer()
                                    
                                    if isPrimary {
                                        Image(systemName: "star.fill") // Étoile pour le chef
                                            .foregroundColor(.yellow)
                                    } else if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                    }
                                }
                                .padding()
                                // Couleur conditionnelle : Or pour Primary, Bleu pour les autres
                                .background(
                                    isPrimary ? Color.yellow.opacity(0.2) :
                                    (isSelected ? Color.blue.opacity(0.6) : Color.white.opacity(0.05))
                                )
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            isPrimary ? Color.yellow :
                                            (isSelected ? Color.blue : Color.white.opacity(0.1)),
                                            lineWidth: isPrimary ? 2 : 1
                                        )
                                )
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: startGame) {
                    HStack {
                        Text("START SIMULATION").font(.headline).fontWeight(.heavy)
                        Image(systemName: "play.fill")
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(isValid ? Color.green : Color.gray.opacity(0.3))
                    .foregroundColor(isValid ? .black : .white.opacity(0.5))
                    .cornerRadius(16)
                }
                .disabled(!isValid)
            }
            .padding(40)
            .frame(maxWidth: .infinity)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationDestination(isPresented: $navigateToGame) {
            if let state = createdGameState {
                MainGameView(gameState: state)
            }
        }
    }
    
    // LOGIQUE MISE À JOUR
    func toggleCountry(_ country: Country) {
        if let index = selectedCountries.firstIndex(of: country) {
            // Si on clique sur un pays déjà sélectionné, on le retire
            selectedCountries.remove(at: index)
        } else {
            // Si on ajoute, on vérifie la limite
            if selectedCountries.count < 5 {
                selectedCountries.append(country)
            }
        }
    }
    
    func startGame() {
        guard let mode = selectedMode, !selectedCountries.isEmpty, selectedCountries.count <= 5 else { return }
        
        // --- CORRECTIF IMPORTANT ---
        // Avant de créer une nouvelle partie, on nettoie la base de données en mémoire
        // pour effacer les traces de l'ancienne partie (matchs, classements, statuts).
        GameDatabase.shared.resetSimulationData()
        // ---------------------------
        
        let newGame = GameState.createNew(
            slotId: slotId,
            mode: mode,
            countries: selectedCountries // L'ordre est conservé (le premier est Primary)
        )
        
        if SaveManager.shared.save(gameState: newGame, slotId: slotId) {
            self.createdGameState = newGame
            self.navigateToGame = true
        } else {
            print("Erreur critique lors de la sauvegarde")
        }
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack {
        NewGameSetupView(slotId: 1)
    }
}
