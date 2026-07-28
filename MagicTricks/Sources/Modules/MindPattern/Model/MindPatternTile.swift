//
//  MindPatternTile.swift
//  Magic Tricks
//
//  Created by Ross on 17/04/2026.
//

import SwiftUI

struct MindPatternTile: Identifiable {
    let animal: MindPatternAnimal
    let color: Color
    let height: CGFloat
    let rotation: Double

    var id: MindPatternAnimal { animal }
}

enum MindPatternAnimal: Identifiable {
    case ant
    case bird
    case fish
    case rabbit
    case turtle
    case dog

    var id: Self { self }

    var signalCount: Int {
        switch self {
        case .ant: 1
        case .bird: 2
        case .fish: 3
        case .rabbit: 4
        case .turtle: 5
        case .dog: 6
        }
    }

    var symbolName: String {
        switch self {
        case .ant: "ant.fill"
        case .bird: "bird.fill"
        case .fish: "fish.fill"
        case .rabbit: "hare.fill"
        case .turtle: "tortoise.fill"
        case .dog: "dog.fill"
        }
    }

    var localizedName: String {
        switch self {
        case .ant: String(localized: "mindPattern.animal.ant")
        case .bird: String(localized: "mindPattern.animal.bird")
        case .fish: String(localized: "mindPattern.animal.fish")
        case .rabbit: String(localized: "mindPattern.animal.rabbit")
        case .turtle: String(localized: "mindPattern.animal.turtle")
        case .dog: String(localized: "mindPattern.animal.dog")
        }
    }
}

let defaultMindPatternTiles: [MindPatternTile] = [
    MindPatternTile(animal: .ant, color: TrickPalette.MindPattern.red, height: 162, rotation: -1.5),
    MindPatternTile(animal: .bird, color: TrickPalette.MindPattern.blue, height: 162, rotation: 1.5),
    MindPatternTile(animal: .fish, color: TrickPalette.MindPattern.green, height: 162, rotation: -1),
    MindPatternTile(animal: .rabbit, color: TrickPalette.MindPattern.orange, height: 162, rotation: 1),
    MindPatternTile(animal: .turtle, color: TrickPalette.MindPattern.purple, height: 162, rotation: -1),
    MindPatternTile(animal: .dog, color: TrickPalette.MindPattern.cyan, height: 162, rotation: 1.5)
]
