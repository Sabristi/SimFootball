//
//  SocialButtons.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 23/11/2025.
//

import SwiftUI

struct SocialButton: View {
    let iconName: String // Peut être un nom SF Symbol ou une image d'asset
    let color: Color
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(color.opacity(0.5), lineWidth: 1)
                    )
                
                Image(systemName: iconName) // Utilise "bubble.left.fill" pour Discord par exemple si pas d'image custom
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
            }
        }
    }
}
