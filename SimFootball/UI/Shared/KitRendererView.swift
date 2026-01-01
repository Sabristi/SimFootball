//
//  KitRendererView.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import SwiftUI

struct KitRendererView: View {
    let kit: Kit
    
    // MARK: - Extraction sécurisée des couleurs
    // On s'assure d'avoir toujours une valeur, même si le tableau est incomplet
    var primaryColor: String {
        kit.jerseyColors.first ?? "#FFFFFF"
    }
    
    var secondaryColor: String {
        kit.jerseyColors.count > 1 ? kit.jerseyColors[1] : primaryColor
    }
    
    var thirdColor: String {
        // Si pas de 3ème couleur définie, on utilise souvent la secondaire ou blanc par défaut
        kit.jerseyColors.count > 2 ? kit.jerseyColors[2] : "#FFFFFF"
    }
    
    // MARK: - Rendu
    var body: some View {
        // Construction du nom du fichier Asset (ex: "KIT_VerticalStripes")
        // Assurez-vous que vos images dans Assets.xcassets commencent bien par "KIT_"
        let assetName = "KIT_\(kit.pattern.rawValue)"
        
        GeometryReader { geo in
            ZStack {
                // 1. Chargement de l'image native (NSImage ou UIImage)
                if let platformImage = PlatformImage(named: assetName) {
                    
                    // 2. Application du moteur de colorisation (Pixel Replacement)
                    if let colorizedImage = platformImage.colorized(
                        base: kit.jerseyColors.first ?? "#999999",
                        pattern1: kit.jerseyColors.count > 1 ? kit.jerseyColors[1] : "#FFFFFF",
                        pattern2: kit.jerseyColors.count > 2 ? kit.jerseyColors[2] : "#FFFFFF",
                        collar: kit.collarColor,
                        sponsor: kit.sponsorColor,
                        logo: kit.logoColor,
                        shorts: kit.shortsColor,
                        socks: kit.socksColor
                    ){
                        // 3. Affichage du résultat final
                        Image(platformImage: colorizedImage)
                            .resizable()
                            // IMPORTANT : .none garde les pixels "carrés" et nets (Pixel Art style)
                            // Si vous mettez .high, ça deviendra flou.
                            .interpolation(.none)
                            .scaledToFit()
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 2)
                        
                    } else {
                        // Erreur technique lors de la colorisation
                        errorFallback
                    }
                    
                } else {
                    // L'image n'existe pas dans les Assets
                    missingAssetFallback
                }
            }
            // Centre l'image dans le conteneur disponible
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        // Force un ratio d'aspect pour éviter les déformations (le t-shirt est plus haut que large)
        .aspectRatio(0.6, contentMode: .fit)
    }
    
    // MARK: - Fallbacks (En cas d'erreur)
    
    var errorFallback: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text("Color Error").font(.caption2)
        }
    }
    
    var missingAssetFallback: some View {
        VStack {
            Image(systemName: "tshirt")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(hex: primaryColor))
                .opacity(0.3)
        }
    }
}

// MARK: - Prévisualisation pour Xcode
struct KitRendererView_Previews: PreviewProvider {
    static var previews: some View {
        let demoKit = Kit(
            type: .home,
            pattern: .verticalStripes, // Assurez-vous d'avoir "KIT_VerticalStripes" dans les assets
            jerseyColors: ["#FF0000", "#FFFFFF", "#00FF00"], // Rouge, Blanc, Vert
            shortsColor: "#000000", // Noir
            socksColor: "#FF0000"   // Rouge
        )
        
        KitRendererView(kit: demoKit)
            .frame(width: 200, height: 300)
            .padding()
            .background(Color.gray.opacity(0.2))
    }
}
