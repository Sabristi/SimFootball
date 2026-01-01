//
//  PlatformUtils.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 14/12/2025.
//

import SwiftUI

// --- DÉFINITIONS GLOBALES (Une seule fois pour tout le projet) ---

#if os(macOS)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformColor = NSColor
#else
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformColor = UIColor
#endif

// Extension pratique pour transformer une PlatformImage en Image SwiftUI directement
extension Image {
    init(platformImage: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: platformImage)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}
