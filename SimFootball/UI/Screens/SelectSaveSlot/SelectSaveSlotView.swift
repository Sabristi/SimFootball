import SwiftUI

struct SelectSaveSlotView: View {
    @Environment(\.dismiss) var dismiss
    
    // Données
    @State private var slots: [SaveSlot] = []
    
    // Navigation
    @State private var selectedSlotIdForNewGame: Int? = nil
    @State private var loadedGameToPlay: GameState? = nil
    
    // Gestion de la suppression (Alert)
    @State private var showDeleteConfirmation: Bool = false
    @State private var slotToDelete: Int? = nil // On stocke quel slot l'utilisateur veut supprimer
    
    var body: some View {
        ZStack {
            // --- BACKGROUND ---
            Color.black.ignoresSafeArea()
            Circle().fill(Color.green.opacity(0.1)).frame(width: 800).blur(radius: 150).offset(x: -400, y: -300)
            Circle().fill(Color.blue.opacity(0.05)).frame(width: 600).blur(radius: 100).offset(x: 400, y: 300)
            
            // --- CONTENU ---
            VStack(spacing: 0) {
                
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.circle.fill").font(.title2)
                            Text("Back").fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10).padding(.horizontal, 20)
                        .background(Color.white.opacity(0.1)).cornerRadius(20)
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Text("SELECT SAVE SLOT")
                            .font(.headline).tracking(3).foregroundColor(.white.opacity(0.7))
                        Text("Manage your career files")
                            .font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    Color.clear.frame(width: 90, height: 40)
                }
                .padding(.horizontal, 40).padding(.top, 20)
                
                Spacer()
                
                // GRILLE
                HStack(spacing: 20) {
                    if slots.isEmpty {
                        ProgressView().tint(.green)
                    } else {
                        ForEach(slots) { slot in
                            SaveSlotCard(
                                slot: slot,
                                onAction: { handleSlotClick(slot: slot) },
                                onDelete: { requestDelete(slotId: slot.id) } // <- Nouvelle action
                            )
                            .frame(maxWidth: .infinity, maxHeight: 350)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { refreshSlots() }
        .navigationDestination(item: $selectedSlotIdForNewGame) { slotId in NewGameSetupView(slotId: slotId) }
        .navigationDestination(item: $loadedGameToPlay) { gameState in MainGameView(gameState: gameState) }
        
        // --- ALERTE DE CONFIRMATION DE SUPPRESSION ---
        .alert("Delete Save File?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let id = slotToDelete {
                    confirmDelete(slotId: id)
                }
            }
        } message: {
            Text("This action cannot be undone. Your progress will be lost forever.")
        }
    }
    
    // MARK: - Logique
    
    func refreshSlots() {
        var loadedSlots: [SaveSlot] = []
        for i in 1...4 {
            if let gameState = SaveManager.shared.load(slotId: i) {
                // Création du slot avec les vraies données
                let slot = SaveSlot(
                    id: i,
                    isEmpty: false,
                    managerName: "Manager",
                    teamName: gameState.gameMode.rawValue, // Affiche le Mode (Owner/Manager)
                    seasonYear: "2025/2026", // Tu pourras calculer ça dynamiquement plus tard
                    lastPlayed: gameState.currentDate // Affiche la date simulée du jeu
                )
                loadedSlots.append(slot)
            } else {
                loadedSlots.append(SaveSlot.empty(id: i))
            }
        }
        self.slots = loadedSlots
    }
    
    func handleSlotClick(slot: SaveSlot) {
        if slot.isEmpty {
            selectedSlotIdForNewGame = slot.id
        } else {
            if let game = SaveManager.shared.load(slotId: slot.id) {
                loadedGameToPlay = game
            }
        }
    }
    
    // 1. L'utilisateur clique sur la poubelle -> On ouvre l'alerte
    func requestDelete(slotId: Int) {
        self.slotToDelete = slotId
        self.showDeleteConfirmation = true
    }
    
    // 2. L'utilisateur confirme -> On supprime et on rafraîchit
    func confirmDelete(slotId: Int) {
        SaveManager.shared.deleteSave(slotId: slotId)
        refreshSlots() // Recharge l'UI immédiatement pour montrer le slot vide
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack {
        SelectSaveSlotView()
    }
}
