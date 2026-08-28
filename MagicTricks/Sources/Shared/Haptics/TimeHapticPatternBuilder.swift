//
//  TimeHapticPatternBuilder.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import CoreHaptics
import Foundation

enum TimeHapticPatternBuilder {
    static func timeValueEvents(tens: Int, ones: Int, initialDelay: TimeInterval) -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        var time = initialDelay

        time = appendDigitEvents(tens, to: &events, startTime: time)
        time += TimeControlHapticPattern.digitGap
        _ = appendDigitEvents(ones, to: &events, startTime: time)

        return events
    }

    static func fallbackDigitImpactTimes(_ digit: Int, startTime: TimeInterval) -> [TimeInterval] {
        guard digit > 0 else { return [startTime] }

        return (0..<digit).map { index in
            startTime + TimeInterval(index) * TimeControlHapticPattern.pulseGap
        }
    }

    static func nextDigitStartTime(_ digit: Int, startTime: TimeInterval) -> TimeInterval {
        startTime + TimeControlHapticPattern.digitDuration(digit)
    }

    @discardableResult
    private static func appendDigitEvents(
        _ digit: Int,
        to events: inout [CHHapticEvent],
        startTime: TimeInterval
    ) -> TimeInterval {
        let intensity = HapticPreferences.intensity.coreHapticsValue

        guard digit > 0 else {
            events.append(
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
                    ],
                    relativeTime: startTime,
                    duration: TimeControlHapticPattern.zeroDuration
                )
            )
            return startTime + TimeControlHapticPattern.zeroDuration
        }

        for index in 0..<digit {
            events.append(
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
                    ],
                    relativeTime: startTime + TimeInterval(index) * TimeControlHapticPattern.pulseGap
                )
            )
        }

        return startTime + TimeControlHapticPattern.digitDuration(digit)
    }
}
