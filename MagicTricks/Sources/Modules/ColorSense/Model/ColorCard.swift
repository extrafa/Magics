//
//  ColorCard.swift
//  Magic Tricks
//
//  Created by Ross on 05/04/2026.
//

import Foundation

struct ColorCard: Identifiable {
    let id = UUID()
    let colorType: ColorCardType
    let title: String
}

enum ColorCardType {
    case red
    case blue
    case green
    case yellow

    var vibrations: Int {
        switch self {
        case .red: 1
        case .green: 2
        case .blue: 3
        case .yellow: 4
        }
    }
}
