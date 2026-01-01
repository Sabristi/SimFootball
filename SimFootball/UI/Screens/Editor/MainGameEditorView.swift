import SwiftUI

struct MainGameEditorView: View {
    @Environment(\.dismiss) var dismiss
    
    // On met .clubs par défaut pour faciliter votre travail actuel,
    // mais vous pouvez remettre .confederations si vous préférez.
    @State private var currentTab: EditorTab = .clubs
    
    var body: some View {
        ZStack {
            // FOND VIOLET EDIT (Thème sombre spécifique à l'éditeur)
            Color.black.ignoresSafeArea()
            ZStack {
                Circle().fill(Color.purple.opacity(0.15)).frame(width: 800).blur(radius: 150).offset(x: -200, y: -300)
                Circle().fill(Color.blue.opacity(0.1)).frame(width: 600).blur(radius: 120).offset(x: 400, y: 200)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // HEADER FIXE
                EditorHeader(
                    title: currentTab.rawValue,
                    onBack: {
                        dismiss()
                    },
                    onSave: {
                        // Action 1 : Sauvegarde interne (Simulateur -> Documents)
                        print("💾 Action: Sauvegarde DB interne...")
                        GameDatabase.shared.saveClubs()
                    },
                    onCopyJSON: {
                        // Action 2 : Copie dans le presse-papier (Pour coller dans Xcode)
                        print("📋 Action: Export JSON vers presse-papier...")
                        GameDatabase.shared.exportJSONToClipboard()
                    }
                )
                .zIndex(10)
                
                // CORPS PRINCIPAL
                HStack(spacing: 0) {
                    
                    // SIDEBAR FIXE
                    EditorSidebar(selectedTab: $currentTab)
                        .zIndex(5)
                    
                    // LISTE CENTRALE VARIABLE
                    ZStack {
                        Color.clear // Zone transparente pour voir le fond global
                        
                        switch currentTab {
                        case .confederations:
                            ConfederationEditorList()
                        case .countries:
                            CountryEditorList()
                        case .stadiums:
                            StadiumEditorList()
                        case .clubs:
                            ClubEditorList()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .statusBar(hidden: true)
        #endif
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack {
        MainGameEditorView()
    }
}
