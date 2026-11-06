//
//  TrickPalette.swift
//  Magic Tricks
//
//  Created by Ross on 29/05/2026.
//

import SwiftUI

enum TrickPalette {
    static let accentPrimary = Color.accentPrimary

    static let proGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.58, blue: 0.08),
            Color(red: 1.0, green: 0.28, blue: 0.42)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    enum Collection {
        static let colorSense = Color.collectionColorSense
        static let timeControl = Color.collectionTimeControl
        static let magicGallery = Color.collectionMagicGallery
        static let geoMentalism = Color.collectionGeoMentalism
        static let phantomDraw = Color.collectionPhantomDraw
    }

    enum Difficulty {
        static let easy = Color.difficultyEasy
        static let medium = Color.difficultyMedium
        static let hard = Color.difficultyHard
    }

    enum ColorSense {
        static let red = Color.colorSenseRed
        static let blue = Color.colorSenseBlue
        static let green = Color.colorSenseGreen
        static let yellow = Color.colorSenseYellow
    }

}

extension TrickType {
    // For text on the screen background: darker in the light theme and lighter in the dark one,
    // so a trick name keeps at least 4.5:1 contrast. Cards and icons use collectionColor.
    var textColor: Color {
        switch self {
        case .colorSense: Color(light: 0x9546BD, dark: 0xB863E2)
        case .timeControl: Color(light: 0x207096, dark: 0x32ADE6)
        case .magicGallery: Color(light: 0x5856D6, dark: 0x7978DE)
        case .geoMentalism: Color(light: 0x1F7735, dark: 0x34C759)
        case .phantomDraw: Color(light: 0xBF2947, dark: 0xFF375F)
        }
    }

    var collectionColor: Color {
        switch self {
        case .colorSense: TrickPalette.Collection.colorSense
        case .timeControl: TrickPalette.Collection.timeControl
        case .magicGallery: TrickPalette.Collection.magicGallery
        case .geoMentalism: TrickPalette.Collection.geoMentalism
        case .phantomDraw: TrickPalette.Collection.phantomDraw
        }
    }
}

extension InstructionPhase {
    var color: Color {
        switch self {
        case .preparation: .blue
        case .demonstration: .green
        }
    }
}

extension TrickDifficulty {
    var color: Color {
        switch self {
        case .easy: TrickPalette.Difficulty.easy
        case .medium: TrickPalette.Difficulty.medium
        case .hard: TrickPalette.Difficulty.hard
        }
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
