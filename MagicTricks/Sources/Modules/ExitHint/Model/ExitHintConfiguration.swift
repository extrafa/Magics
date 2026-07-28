import CoreGraphics
import Foundation
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
        case .normal:
            return Color.primaryText.opacity(0.36)
        case .specialWhite:
            return Color.defaultText.opacity(0.36)
        case .specialBlack:
            return Color.black.opacity(0.55)
        }
    }

    var fillColor: Color {
        switch self {
        case .normal:
            return Color.primaryText.opacity(0.04)
        case .specialWhite:
            return Color.defaultText.opacity(0.04)
        case .specialBlack:
            return Color.black.opacity(0.06)
        }
    }

    var textColor: Color {
        switch self {
        case .normal:
            return Color.primaryText.opacity(0.62)
        case .specialWhite:
            return Color.defaultText.opacity(0.62)
        case .specialBlack:
            return Color.black.opacity(0.62)
        }
    }

}
