//
//  TimeHapticPatternBuilder.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import CoreHaptics
import Foundation

enum TimeHapticPatternBuilder {
    static func timeValueEvents(tens: Int, ones: Int, initialDelay: TimeInterval, timings: HapticTimings) -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        let tensEnd = appendDigitEvents(tens, to: &events, startTime: initialDelay, timings: timings)
        appendDigitEvents(ones, to: &events, startTime: tensEnd + timings.digitGap, timings: timings)
        return events
    }

    static func fallbackDigitImpactTimes(_ digit: Int, startTime: TimeInterval, timings: HapticTimings) -> [TimeInterval] {
        guard digit > 0 else { return [startTime] }

        return (0..<digit).map { index in
            startTime + TimeInterval(index) * timings.pulseGap
        }
    }

    static func nextDigitStartTime(_ digit: Int, startTime: TimeInterval, timings: HapticTimings) -> TimeInterval {
        startTime + timings.digitDuration(digit)
    }

    @discardableResult
    private static func appendDigitEvents(
        _ digit: Int,
        to events: inout [CHHapticEvent],
        startTime: TimeInterval,
        timings: HapticTimings
    ) -> TimeInterval {
        let intensity = timings.intensity.coreHapticsValue

        guard digit > 0 else {
            events.append(
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
                    ],
                    relativeTime: startTime,
                    duration: timings.zeroDuration
                )
            )
            return startTime + timings.zeroDuration
        }

        for index in 0..<digit {
            events.append(
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
                    ],
                    relativeTime: startTime + TimeInterval(index) * timings.pulseGap
                )
            )
        }

        return startTime + timings.digitDuration(digit)
    }
}
