import SwiftUI

struct MainGameEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentTab: EditorTab = .confederations
    
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
                    onBack: { dismiss() },
                    onSave: {
                        print("💾 Simulation: Sauvegarde des JSON sur le disque...")
                        // TODO: Implémenter la sauvegarde JSON réelle via SaveManager
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
