//
//  TrickPalette.swift
//  Magic Tricks
//
//  Created by Ross on 29/05/2026.
//

import SwiftUI

enum TrickPalette {
    static let accentPrimary = Color("accentPrimary")

    enum Difficulty {
        static let easy = Color("difficultyEasy")
        static let medium = Color("collectionCalculatorPrediction")
        static let hard = Color("difficultyHard")
    }

    enum Collection {
        static let colorSense = Color("collectionColorSense")
        static let calculatorPrediction = Color("collectionCalculatorPrediction")
        static let timeControl = Color("collectionTimeControl")
        static let magicGallery = Color("collectionMagicGallery")
        static let geoMentalism = Color("collectionGeoMentalism")
        static let phantomDraw = Color("collectionPhantomDraw")
    }

    enum ColorSense {
        static let red = Color("colorSenseRed")
        static let blue = Color("colorSenseBlue")
        static let green = Color("colorSenseGreen")
        static let yellow = Color("colorSenseYellow")
    }

}

extension TrickType {
    var collectionColor: Color {
        switch self {
        case .colorSense: TrickPalette.Collection.colorSense
        case .calculatorPrediction: TrickPalette.Collection.calculatorPrediction
        case .timeControl: TrickPalette.Collection.timeControl
        case .magicGallery: TrickPalette.Collection.magicGallery
        case .geoMentalism: TrickPalette.Collection.geoMentalism
        case .phantomDraw: TrickPalette.Collection.phantomDraw
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
