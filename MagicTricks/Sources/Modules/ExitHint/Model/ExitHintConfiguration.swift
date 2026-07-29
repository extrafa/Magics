//
//  ExitHintConfiguration.swift
//  Magic Tricks
//
//  Created by Ross on 09/04/2026.
//

import SwiftUI

@MainActor
final class ExitHintGestureState {
    static let shared = ExitHintGestureState()
    var globalRect: CGRect = .zero
    var isTrainingActive = false
    var onTrainingHold: (() -> Void)?
    var onOutsideTap: (() -> Void)?
}

enum ExitHintZone {
    static let frame = CGSize(width: 250, height: 220)
    static let minimumPressDuration: TimeInterval = 1.5
}

enum ExitHintStyle {
    case normal
    case specialWhite
    case specialBlack

    var strokeColor: Color {
        switch self {
        case .normal: Color.primaryText.opacity(0.36)
        case .specialWhite: Color.defaultText.opacity(0.36)
        case .specialBlack: Color.black.opacity(0.55)
        }
    }

    var fillColor: Color {
        switch self {
        case .normal: Color.primaryText.opacity(0.04)
        case .specialWhite: Color.defaultText.opacity(0.04)
        case .specialBlack: Color.black.opacity(0.06)
        }
    }

    var textColor: Color {
        switch self {
        case .normal: Color.primaryText.opacity(0.62)
        case .specialWhite: Color.defaultText.opacity(0.62)
        case .specialBlack: Color.black.opacity(0.62)
        }
    }

}
