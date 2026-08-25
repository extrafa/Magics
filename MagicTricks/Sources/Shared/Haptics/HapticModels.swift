//
//  HapticModels.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation
import UIKit

enum HapticIntensity: Equatable, Hashable {
    case light
    case medium
    case heavy

    static let allCases: [HapticIntensity] = [.light, .medium, .heavy]

    var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: .light
        case .medium: .medium
        case .heavy: .heavy
        }
    }

    var impactIntensity: CGFloat {
        switch self {
        case .light: 1.0 / 3.0
        case .medium: 2.0 / 3.0
        case .heavy: 1.0
        }
    }

    var localizedTitle: String {
        switch self {
        case .light: String(localized: "settings.haptics.intensity.weak")
        case .medium: String(localized: "settings.haptics.intensity.medium")
        case .heavy: String(localized: "settings.haptics.intensity.strong")
        }
    }
}

enum HapticTiming {
    static let initialDelay: TimeInterval = 0
    static let pulseGap: TimeInterval = 0.32
    static let digitGap: TimeInterval = 1.15
    static let sectionGap: TimeInterval = 3.0
    static let shortDuration: TimeInterval = 0.08
    static let longDuration: TimeInterval = 0.55
    static let completionPadding: TimeInterval = 0.1
}

enum HapticPreferences {
    static let speedKey = AppPreferences.Key.hapticSpeedMultiplier
    static let groupByThreeKey = AppPreferences.Key.hapticGroupByThreeEnabled
    static let defaultSpeedMultiplier = AppPreferences.Default.hapticSpeedMultiplier
    static let defaultGroupByThree = AppPreferences.Default.hapticGroupByThreeEnabled
    static let groupedChunkSize = 3
    static let speedRange = AppPreferences.Range.hapticSpeedMultiplier

    static var speedMultiplier: Double {
        AppPreferences.shared.hapticSpeedMultiplier
    }

    static var isGroupByThreeEnabled: Bool {
        AppPreferences.shared.isHapticGroupByThreeEnabled
    }

    static var intensity: HapticIntensity {
        AppPreferences.shared.hapticIntensity
    }

    static var pulseGap: TimeInterval { max(scaled(HapticTiming.pulseGap), 0.07) }
    static var digitGap: TimeInterval { max(scaled(HapticTiming.digitGap), 1.15) }
    static var sectionGap: TimeInterval { HapticTiming.sectionGap }
    static var shortDuration: TimeInterval { scaled(HapticTiming.shortDuration) }
    static var longDuration: TimeInterval { max(scaled(HapticTiming.longDuration), 0.42) }
    static var completionPadding: TimeInterval { HapticTiming.completionPadding }
    static var groupedPulseGap: TimeInterval { groupTiming.pulseGap }
    static var groupedRemainderPulseGap: TimeInterval { groupTiming.remainderPulseGap }
    static var groupedGroupGap: TimeInterval { groupTiming.groupGap }

    // Per-speed group timing. Ratio groupGap/pulseGap is held at ~3.7:1 across
    // all speeds — the brain reliably detects a boundary at 3.5x the within-group
    // interval. Gaps much longer than ~1s break the pattern thread; shorter than
    // 2.5x the pulse gap and the boundary disappears.
    private static var groupTiming: (pulseGap: TimeInterval, remainderPulseGap: TimeInterval, groupGap: TimeInterval) {
        let s = speedMultiplier
        if s >= 2.25 {
            return (pulseGap: 0.10, remainderPulseGap: 0.14, groupGap: 0.36)
        } else if s >= 1.75 {
            return (pulseGap: 0.115, remainderPulseGap: 0.15, groupGap: 0.40)
        } else if s >= 1.25 {
            return (pulseGap: 0.13, remainderPulseGap: 0.17, groupGap: 0.46)
        } else {
            return (pulseGap: 0.15, remainderPulseGap: 0.19, groupGap: 0.53)
        }
    }
    static var groupedDigitGap: TimeInterval { digitGap }

    static func reset() {
        AppPreferences.shared.resetHapticSettings()
    }

    private static func scaled(_ value: TimeInterval) -> TimeInterval {
        value / speedMultiplier
    }
}

enum TimeControlHapticPattern {
    static var pulseGap: TimeInterval { HapticPreferences.pulseGap }
    static var digitGap: TimeInterval { HapticPreferences.digitGap }
    static var sectionGap: TimeInterval { HapticPreferences.sectionGap }
    static var zeroDuration: TimeInterval { HapticPreferences.longDuration }

    static func digitDuration(_ digit: Int) -> TimeInterval {
        guard digit > 0 else { return zeroDuration }
        return TimeInterval(digit - 1) * Self.pulseGap
    }
}
