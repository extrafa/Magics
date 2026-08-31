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

    var coreHapticsValue: Float {
        switch self {
        case .light: 0.45
        case .medium: 0.7
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
    static let groupedChunkSize = 3

    // Each must sit strictly between base/2.5 and base — checked by scaledWithFloor's assert.
    static let minPulseGap: TimeInterval = 0.18
    static let minDigitGap: TimeInterval = 0.7
    static let minLongDuration: TimeInterval = 0.42
}

// Computed once from injected preferences instead of reading AppPreferences.shared directly.
struct HapticTimings {
    let pulseGap: TimeInterval
    let digitGap: TimeInterval
    let shortDuration: TimeInterval
    let longDuration: TimeInterval
    let intensity: HapticIntensity
    let isGroupByThreeEnabled: Bool
    let grouped: Grouped

    var zeroDuration: TimeInterval { longDuration }

    init(preferences: HapticPreferenceManaging) {
        let speed = preferences.hapticSpeedMultiplier

        pulseGap = Self.scaledWithFloor(HapticTiming.pulseGap, floor: HapticTiming.minPulseGap, speed: speed)
        digitGap = Self.scaledWithFloor(HapticTiming.digitGap, floor: HapticTiming.minDigitGap, speed: speed)
        shortDuration = HapticTiming.shortDuration / speed
        longDuration = Self.scaledWithFloor(HapticTiming.longDuration, floor: HapticTiming.minLongDuration, speed: speed)
        isGroupByThreeEnabled = preferences.isHapticGroupByThreeEnabled
        intensity = preferences.hapticIntensity
        grouped = Grouped(speed: speed, digitGap: digitGap)
    }

    func digitDuration(_ digit: Int) -> TimeInterval {
        guard digit > 0 else { return zeroDuration }
        return TimeInterval(digit - 1) * pulseGap
    }

    private static func scaledWithFloor(_ base: TimeInterval, floor: TimeInterval, speed: Double) -> TimeInterval {
        assert(floor > base / AppPreferences.Range.hapticSpeedMultiplier.upperBound && floor < base)
        return max(base / speed, floor)
    }

    struct Grouped {
        let pulseGap: TimeInterval
        let remainderPulseGap: TimeInterval
        let groupGap: TimeInterval
        let digitGap: TimeInterval

        // Ratio ~3.7:1 (groupGap:pulseGap) keeps the group boundary perceptible; tuned per speed tier.
        init(speed: Double, digitGap: TimeInterval) {
            let tier: (pulseGap: TimeInterval, remainderPulseGap: TimeInterval, groupGap: TimeInterval)
            if speed >= 2.25 {
                tier = (0.10, 0.14, 0.36)
            } else if speed >= 1.75 {
                tier = (0.115, 0.15, 0.40)
            } else if speed >= 1.25 {
                tier = (0.13, 0.17, 0.46)
            } else {
                tier = (0.15, 0.19, 0.53)
            }
            self.pulseGap = tier.pulseGap
            self.remainderPulseGap = tier.remainderPulseGap
            self.groupGap = tier.groupGap
            self.digitGap = digitGap
        }
    }
}
