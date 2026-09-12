//
//  Trick.swift
//  Magic Tricks
//
//  Created by Ross on 30/11/2025.
//

import Foundation

enum TrickType: String, CaseIterable {
    // Declaration order is also the Collection screen's display order (allCases).
    case geoMentalism
    case colorSense
    case calculatorPrediction
    case timeControl
    case magicGallery
    case phantomDraw

    var requiresPro: Bool {
        switch self {
        case .geoMentalism: false
        case .colorSense, .calculatorPrediction, .timeControl, .magicGallery, .phantomDraw: true
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
    let title: LocalizedStringResource
    let cardTitle: LocalizedStringResource?
    let subtitle: LocalizedStringResource
    let image: String
    let difficulty: TrickDifficulty
    let instruction: Instruction

    init(
        id: TrickType,
        title: LocalizedStringResource,
        cardTitle: LocalizedStringResource? = nil,
        subtitle: LocalizedStringResource,
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

    // LocalizedStringResource isn't Hashable, so equality/hashing is id-based (each Trick maps 1:1 to its id anyway).
    static func == (lhs: Trick, rhs: Trick) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension TrickType {
    var trick: Trick {
        switch self {
        case .geoMentalism:
            Trick(
                id: .geoMentalism,
                title: "card.geo.title",
                cardTitle: "card.geo.cardTitle",
                subtitle: "card.geo.subtitle",
                image: "globe.europe.africa.fill",
                difficulty: .medium,
                instruction: .geoMentalism
            )
        case .colorSense:
            Trick(
                id: .colorSense,
                title: "card.color.title",
                cardTitle: "card.color.cardTitle",
                subtitle: "card.color.subtitle",
                image: "paintpalette",
                difficulty: .easy,
                instruction: .colorSense
            )
        case .calculatorPrediction:
            Trick(
                id: .calculatorPrediction,
                title: "card.calculatorPrediction.title",
                cardTitle: "card.calculatorPrediction.cardTitle",
                subtitle: "card.calculatorPrediction.subtitle",
                image: "ipad",
                difficulty: .medium,
                instruction: .calculatorPrediction
            )
        case .timeControl:
            Trick(
                id: .timeControl,
                title: "card.time.title",
                subtitle: "card.time.subtitle",
                image: "stopwatch.fill",
                difficulty: .medium,
                instruction: .timeControl
            )
        case .magicGallery:
            Trick(
                id: .magicGallery,
                title: "card.magicGallery.title",
                subtitle: "card.magicGallery.subtitle",
                image: "photo.on.rectangle.angled",
                difficulty: .hard,
                instruction: .magicGallery
            )
        case .phantomDraw:
            Trick(
                id: .phantomDraw,
                title: "card.phantomDraw.title",
                cardTitle: "card.phantomDraw.cardTitle",
                subtitle: "card.phantomDraw.subtitle",
                image: "antenna.radiowaves.left.and.right",
                difficulty: .easy,
                instruction: .phantomDraw
            )
        }
    }
}

enum TrickCollection {
    static let tricks: [Trick] = TrickType.allCases.map(\.trick)
}
