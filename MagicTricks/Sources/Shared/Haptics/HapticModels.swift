//
//  HapticModels.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

enum HapticTiming {
    static let initialDelay: TimeInterval = 0
    static let pulseGap: TimeInterval = 0.36
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

    static var pulseGap: TimeInterval { max(scaled(HapticTiming.pulseGap), 0.2) }
    static var digitGap: TimeInterval { max(scaled(HapticTiming.digitGap), 1.15) }
    static var sectionGap: TimeInterval { HapticTiming.sectionGap }
    static var shortDuration: TimeInterval { scaled(HapticTiming.shortDuration) }
    static var longDuration: TimeInterval { max(scaled(HapticTiming.longDuration), 0.42) }
    static var completionPadding: TimeInterval { HapticTiming.completionPadding }
    static var groupedPulseGap: TimeInterval { max(scaled(0.19), 0.12) }
    static var groupedRemainderPulseGap: TimeInterval { max(scaled(0.28), 0.18) }
    static var groupedGroupGap: TimeInterval { max(scaled(0.68), 0.52) }
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
