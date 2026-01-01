//
//  SideMenuItem.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 30/11/2025.
//

import SwiftUI

struct SideMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String // SF Symbol
    let color: Color // Couleur de la petite barre latérale (Style FM)
    let action: () -> Void
}
