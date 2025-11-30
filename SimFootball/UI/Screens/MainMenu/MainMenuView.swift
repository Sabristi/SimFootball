import SwiftUI

struct MainMenuView: View {
    @State private var navigateToSaveSlots: Bool = false
    @State private var navigateToEditor: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // --- BACKGROUND ---
                Color.black.ignoresSafeArea()
                Circle().fill(Color.green.opacity(0.15)).frame(width: 600).blur(radius: 120).offset(x: -300, y: -200)
                Circle().fill(Color.blue.opacity(0.1)).frame(width: 500).blur(radius: 120).offset(x: 400, y: 300)
                
                // --- LAYOUT ---
                HStack(spacing: 20) {
                    
                    // GAUCHE : LOGO & SLOGAN
                    VStack(alignment: .center, spacing: 0) {
                        Spacer()
                        
                        // LOGO
                        Image("GameLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 280, height: 280)
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 10)
                        
                        Spacer()
                        
                        // SLOGAN
                        HStack(spacing: 8) {
                            Rectangle().fill(Color.green).frame(width: 4, height: 30)
                            Text("BUILD YOUR LEGACY.\nDOMINATE THE WORLD.")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.bottom, 30)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // DROITE : MENU
                    VStack(spacing: 20) {
                        
                        Spacer()
                        
                        // 1. STORY MODE (Vert)
                        BentoCard(
                            title: "Story Mode",
                            subtitle: "Build your legacy",
                            icon: "trophy.fill",
                            color: .green
                        ) {
                            navigateToSaveSlots = true
                        }
                        .frame(height: 90)
                        
                        // 2. EXHIBITION (Bleu)
                        BentoCard(
                            title: "Exhibition",
                            subtitle: "Quick simulation",
                            icon: "soccerball",
                            color: .blue
                        ) {
                            print("Exhibition")
                        }
                        .frame(height: 90)
                        
                        // 3. EDITOR & SETTINGS (Ligne du bas)
                        HStack(spacing: 15) {
                            // Editor (Orange)
                            BentoCard(
                                title: "Editor",
                                icon: "hammer.fill",
                                color: .orange
                            ) { navigateToEditor = true }
                            
                            // Settings (Mauve)
                            BentoCard(
                                title: "Settings",
                                icon: "gearshape.fill",
                                color: .purple
                            ) { print("Settings") }
                        }
                        .frame(height: 80)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // 4. SOCIALS (Seulement les icones, alignées à droite)
                        HStack {
                            Spacer() // Pousse tout vers la droite
                            
                            HStack(spacing: 12) {
                                SocialButton(iconName: "bubble.left.and.bubble.right.fill", color: .indigo, url: "https://discord.com")
                                SocialButton(iconName: "network", color: .blue, url: "https://twitter.com")
                                SocialButton(iconName: "envelope.fill", color: .red, url: "mailto:support@simfootball.com")
                            }
                        }
                        // On garde une hauteur fixe pour éviter que ça saute
                        .frame(height: 40)
                        
                        Spacer()
                    }
                    .frame(width: 460) // Largeur fixe colonne droite
                }
                .padding(40)
            }
            .navigationDestination(isPresented: $navigateToSaveSlots) {
                SelectSaveSlotView()
            }
            .navigationDestination(isPresented: $navigateToEditor) {
                MainGameEditorView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview(traits: .landscapeLeft) {
    MainMenuView()
        .frame(width: 932, height: 430)
}
