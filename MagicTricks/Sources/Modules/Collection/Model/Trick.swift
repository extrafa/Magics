//
//  Trick.swift
//  Magic Tricks
//
//  Created by Ross on 30/11/2025.
//

import Foundation

enum TrickType: String, CaseIterable {
    // Declaration order is also the Collection screen's display order (allCases).
    // Raw values are pinned to the current case names on purpose - they're persisted in
    // seenTrickIds, so renaming a case here must not change what's already on disk.
    case geoMentalism = "geoMentalism"
    case colorSense = "colorSense"
    case calculatorPrediction = "calculatorPrediction"
    case timeControl = "timeControl"
    case magicGallery = "magicGallery"
    case phantomDraw = "phantomDraw"

    var requiresPro: Bool {
        switch self {
        case .geoMentalism: false
        case .colorSense, .calculatorPrediction, .timeControl, .magicGallery, .phantomDraw: true
        }
    }
}

enum SFSymbol: String {
    case globeEuropeAfricaFill = "globe.europe.africa.fill"
    case paintpalette = "paintpalette"
    case ipad = "ipad"
    case stopwatchFill = "stopwatch.fill"
    case photoOnRectangleAngled = "photo.on.rectangle.angled"
    case antennaRadiowavesLeftAndRight = "antenna.radiowaves.left.and.right"
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
    let image: SFSymbol
    let difficulty: TrickDifficulty
    let instruction: Instruction

    init(
        id: TrickType,
        title: LocalizedStringResource,
        cardTitle: LocalizedStringResource? = nil,
        subtitle: LocalizedStringResource,
        image: SFSymbol,
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
            let key = L10nDomain("card.geo")
            return Trick(
                id: .geoMentalism,
                title: key("title"),
                cardTitle: key("cardTitle"),
                subtitle: key("subtitle"),
                image: .globeEuropeAfricaFill,
                difficulty: .medium,
                instruction: .geoMentalism
            )
        case .colorSense:
            let key = L10nDomain("card.color")
            return Trick(
                id: .colorSense,
                title: key("title"),
                cardTitle: key("cardTitle"),
                subtitle: key("subtitle"),
                image: .paintpalette,
                difficulty: .easy,
                instruction: .colorSense
            )
        case .calculatorPrediction:
            let key = L10nDomain("card.calculatorPrediction")
            return Trick(
                id: .calculatorPrediction,
                title: key("title"),
                cardTitle: key("cardTitle"),
                subtitle: key("subtitle"),
                image: .ipad,
                difficulty: .medium,
                instruction: .calculatorPrediction
            )
        case .timeControl:
            let key = L10nDomain("card.time")
            return Trick(
                id: .timeControl,
                title: key("title"),
                subtitle: key("subtitle"),
                image: .stopwatchFill,
                difficulty: .medium,
                instruction: .timeControl
            )
        case .magicGallery:
            let key = L10nDomain("card.magicGallery")
            return Trick(
                id: .magicGallery,
                title: key("title"),
                subtitle: key("subtitle"),
                image: .photoOnRectangleAngled,
                difficulty: .hard,
                instruction: .magicGallery
            )
        case .phantomDraw:
            let key = L10nDomain("card.phantomDraw")
            return Trick(
                id: .phantomDraw,
                title: key("title"),
                cardTitle: key("cardTitle"),
                subtitle: key("subtitle"),
                image: .antennaRadiowavesLeftAndRight,
                difficulty: .easy,
                instruction: .phantomDraw
            )
        }
    }
}

enum TrickCollection {
    static let tricks: [Trick] = TrickType.allCases.map(\.trick)
}
