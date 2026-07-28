//
//  TrickPalette.swift
//  Magic Tricks
//
//  Created by Ross on 29/05/2026.
//

import SwiftUI

enum TrickPalette {
    enum Difficulty {
        static let easy = Color("collectionMindPattern")
        static let medium = Color("collectionCalculatorPrediction")
        static let hard = Color("difficultyHard")
    }

    enum Collection {
        static let colorSense = Color("collectionColorSense")
        static let mindPattern = Color("collectionMindPattern")
        static let calculatorPrediction = Color("collectionCalculatorPrediction")
        static let timeControl = Color("collectionTimeControl")
        static let magicGallery = Color("collectionMagicGallery")
    }

    enum ColorSense {
        static let red = Color("colorSenseRed")
        static let blue = Color("colorSenseBlue")
        static let green = Color("collectionMindPattern")
        static let yellow = Color("colorSenseYellow")
    }

    enum MindPattern {
        static let red = Color("difficultyHard")
        static let blue = Color("mindPatternBlue")
        static let green = Color("mindPatternGreen")
        static let orange = Color("mindPatternOrange")
        static let purple = Color("mindPatternPurple")
        static let cyan = Color("mindPatternCyan")
    }
}

extension TrickType {
    var collectionColor: Color {
        switch self {
        case .colorMentalism: TrickPalette.Collection.colorSense
        case .mindPattern: TrickPalette.Collection.mindPattern
        case .calculatorPrediction: TrickPalette.Collection.calculatorPrediction
        case .timeControl: TrickPalette.Collection.timeControl
        case .magicGallery: TrickPalette.Collection.magicGallery
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
