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

    var range: ClosedRange<Int> { 0...9 }

    var inputPlaceholder: String { "0–9" }

    var navigationTitle: String { String(localized: "training.digits.title") }

    var subtitle: String { String(localized: "training.digits.subtitle") }

    var playButtonTitle: String { String(localized: "training.digits.playButton") }

    var accentColor: Color { Color.collectionMindPattern }

    var systemIcon: String { "waveform.path.ecg" }
}
