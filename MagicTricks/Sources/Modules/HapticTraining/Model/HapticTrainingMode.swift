//
//  HapticTrainingMode.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

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
        case .digits: 0...9
        case .timeValues: 10...99
        }
    }

    var signalStyle: SignalStyle {
        switch self {
        case .digits: .count
        case .timeValues: .timeValue
        }
    }

    var inputPlaceholder: String { "?" }

    /// When true, the user submits via an explicit button instead of typing a single digit.
    var usesExplicitSubmit: Bool {
        switch self {
        case .digits: false
        case .timeValues: true
        }
    }

    var navigationTitle: String {
        switch self {
        case .digits: String(localized: "training.digits.title")
        case .timeValues: String(localized: "training.values.title")
        }
    }

    var subtitle: String {
        switch self {
        case .digits: String(localized: "training.digits.subtitle")
        case .timeValues: String(localized: "training.values.subtitle")
        }
    }

    var playButtonTitle: String {
        switch self {
        case .digits: String(localized: "training.digits.playButton")
        case .timeValues: String(localized: "training.values.playButton")
        }
    }

    var accentColor: Color {
        switch self {
        case .digits: Color.collectionMindPattern
        case .timeValues: Color.collectionTimeControl
        }
    }

    var systemIcon: String { "waveform.path.ecg" }
}
