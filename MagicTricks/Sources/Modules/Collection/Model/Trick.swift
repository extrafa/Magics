//
//  Trick.swift
//  Magic Tricks
//
//  Created by Ross on 30/11/2025.
//

import Foundation

enum TrickType: String, CaseIterable {
    case colorSense
    case calculatorPrediction
    case timeControl
    case magicGallery
    case geoMentalism
    case phantomDraw

    var requiresPro: Bool {
        switch self {
        case .geoMentalism: false
        default: true
        }
    }
}

enum TrickDifficulty: Hashable {
    case easy
    case medium
    case hard

    var localizedTitle: String {
        switch self {
        case .easy: String(localized: "difficulty.easy")
        case .medium: String(localized: "difficulty.medium")
        case .hard: String(localized: "difficulty.hard")
        }
    }
}

struct Trick: Identifiable, Hashable {
    let id: TrickType
    let title: String
    let cardTitle: String?
    let subtitle: String
    let image: String
    let difficulty: TrickDifficulty
    let instruction: Instruction

    init(
        id: TrickType,
        title: String,
        cardTitle: String? = nil,
        subtitle: String,
        image: String,
        difficulty: TrickDifficulty,
        instruction: Instruction
    ) {
        self.id = id
        self.title = title
        self.cardTitle = cardTitle
        self.subtitle = subtitle
        self.image = image
        self.difficulty = difficulty
        self.instruction = instruction
    }
}

struct TrickCollection {
    static let tricks: [Trick] = [
        Trick(
            id: .geoMentalism,
            title: String(localized: "card.geo.title"),
            cardTitle: String(localized: "card.geo.cardTitle"),
            subtitle: String(localized: "card.geo.subtitle"),
            image: "globe.europe.africa.fill",
            difficulty: .medium,
            instruction: .geoMentalism
        ),
        Trick(
            id: .colorSense,
            title: String(localized: "card.color.title"),
            cardTitle: String(localized: "card.color.cardTitle"),
            subtitle: String(localized: "card.color.subtitle"),
            image: "paintpalette",
            difficulty: .easy,
            instruction: .colorSense
        ),
        Trick(
            id: .calculatorPrediction,
            title: String(localized: "card.calculatorPrediction.title"),
            cardTitle: String(localized: "card.calculatorPrediction.cardTitle"),
            subtitle: String(localized: "card.calculatorPrediction.subtitle"),
            image: "ipad",
            difficulty: .medium,
            instruction: .calculatorPrediction
        ),
        Trick(
            id: .timeControl,
            title: String(localized: "card.time.title"),
            subtitle: String(localized: "card.time.subtitle"),
            image: "stopwatch.fill",
            difficulty: .medium,
            instruction: .timeControl
        ),
        Trick(
            id: .magicGallery,
            title: String(localized: "card.magicGallery.title"),
            subtitle: String(localized: "card.magicGallery.subtitle"),
            image: "photo.on.rectangle.angled",
            difficulty: .hard,
            instruction: .magicGallery
        ),
        Trick(
            id: .phantomDraw,
            title: String(localized: "card.phantomDraw.title"),
            cardTitle: String(localized: "card.phantomDraw.cardTitle"),
            subtitle: String(localized: "card.phantomDraw.subtitle"),
            image: "antenna.radiowaves.left.and.right",
            difficulty: .easy,
            instruction: .phantomDraw
        )
    ]
}
