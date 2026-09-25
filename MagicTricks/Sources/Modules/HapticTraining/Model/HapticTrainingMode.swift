//
//  HapticTrainingMode.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation
import SwiftUI

private let key = L10nDomain("training.digits")

enum HapticTrainingMode {
    case digits

    var range: ClosedRange<Int> { 0...9 }

    var inputPlaceholder: String { "0–9" }

    var navigationTitle: String { String(localized: key("title")) }

    var subtitle: String { String(localized: key("subtitle")) }

    var playButtonTitle: String { String(localized: key("playButton")) }

    var accentColor: Color { TrickPalette.accentPrimary }

    var systemIcon: String { "waveform.path.ecg" }
}
