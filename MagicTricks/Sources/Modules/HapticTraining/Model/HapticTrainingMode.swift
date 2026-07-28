import Foundation
import SwiftUI

enum HapticTrainingMode {
    case digits
    case timeValues

    enum SignalStyle {
        case count
        case timeValue
    }

    var range: ClosedRange<Int> {
        switch self {
        case .digits: return 0...9
        case .timeValues: return 10...99
        }
    }

    var signalStyle: SignalStyle {
        switch self {
        case .digits: return .count
        case .timeValues: return .timeValue
        }
    }

    var inputPlaceholder: String { "?" }

    /// When true, the user submits via an explicit button instead of typing a single digit.
    var usesExplicitSubmit: Bool {
        switch self {
        case .digits: return false
        case .timeValues: return true
        }
    }

    var navigationTitle: String {
        switch self {
        case .digits: return String(localized: "training.digits.title")
        case .timeValues: return String(localized: "training.values.title")
        }
    }

    var subtitle: String {
        switch self {
        case .digits: return String(localized: "training.digits.subtitle")
        case .timeValues: return String(localized: "training.values.subtitle")
        }
    }

    var playButtonTitle: String {
        switch self {
        case .digits: return String(localized: "training.digits.playButton")
        case .timeValues: return String(localized: "training.values.playButton")
        }
    }

    var accentColor: Color {
        switch self {
        case .digits: return Color.collectionMindPattern
        case .timeValues: return Color.collectionTimeControl
        }
    }

    var systemIcon: String {
        switch self {
        case .digits: return "waveform.path.ecg"
        case .timeValues: return "waveform.path.ecg"
        }
    }
}
