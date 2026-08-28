//
//  ExitHintConfiguration.swift
//  Magic Tricks
//
//  Created by Ross on 09/04/2026.
//

import SwiftUI

struct ExitHintRectPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

@MainActor
final class ExitHintGestureCoordinator: ObservableObject {
    var isTrainingActive = false
    var onTrainingHold: (() -> Void)?
    var onOutsideTap: (() -> Void)?
    var onHoldStarted: (() -> Void)?
    var onHoldCancelled: (() -> Void)?
    var onSwipe: (() -> Void)?
}

enum ExitHintZone {
    static let frame = CGSize(width: 250, height: 220)
    static let minimumPressDuration: TimeInterval = 1.5
    static let hitTestMargin: CGFloat = 20
    static let longPressAllowableMovement: CGFloat = 1000
}

enum ExitHintSwipeGesture {
    static let timeLimit: TimeInterval = 0.5
    static let minimumSpeed: CGFloat = 400
}

enum ExitHintOpacity {
    static let visible = 1.0
    static let dimmed = 0.18
    static let hidden = 0.0
}

enum ExitHintHoldScale {
    static let pressed: CGFloat = 0.90
    static let released: CGFloat = 1.0
}

enum ExitHintFlash {
    static let peak = 0.30
    static let rest = 0.0
    static let repeatCount = 2
}

enum ExitHintFadeTiming {
    static let initialDelay: TimeInterval = 2
    static let dimDuration: TimeInterval = 2.2
    static let hideDuration: TimeInterval = 0.8
}

enum ExitHintFlashTiming {
    static let holdAfterPeak: TimeInterval = 0.09
    static let holdAfterRest: TimeInterval = 0.20
}

enum ExitHintFlashAnimation {
    static let fadeInDuration: TimeInterval = 0.07
    static let fadeOutDuration: TimeInterval = 0.16
}

enum ExitHintHoldAnimation {
    static let pressDurationMultiplier: TimeInterval = 1.4
    static let releaseSpringResponse = 0.38
    static let releaseSpringDamping = 0.55
}

enum ExitHintConfirmAnimation {
    static let duration: TimeInterval = 0.22
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
