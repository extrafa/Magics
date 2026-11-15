//
//  GroupedHapticPatternBuilder.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import CoreHaptics
import Foundation

enum GroupedHapticPatternBuilder {

    // When each pulse fires, in groups of three with a longer pause between the groups; the screen can follow the same clock.
    static func pulseTimes(
        count: Int,
        initialDelay: TimeInterval,
        timings: HapticTimings
    ) -> [TimeInterval] {
        let chunkSize = HapticTiming.groupedChunkSize

        var times: [TimeInterval] = []
        var time = initialDelay
        var remaining = count

        while remaining > 0 {
            let groupCount = min(chunkSize, remaining)
            let pulseGap = groupCount < chunkSize
                ? timings.grouped.remainderPulseGap
                : timings.grouped.pulseGap

            for index in 0..<groupCount {
                times.append(time + Double(index) * pulseGap)
            }

            time += Double(groupCount - 1) * pulseGap + timings.grouped.groupGap
            remaining -= groupCount
        }

        return times
    }

    static func groupedCountEvents(
        count: Int,
        initialDelay: TimeInterval,
        timings: HapticTimings
    ) -> (events: [CHHapticEvent], duration: TimeInterval) {
        let intensity = timings.intensity.coreHapticsValue
        let times = pulseTimes(count: count, initialDelay: initialDelay, timings: timings)

        let events = times.map { pulseTime in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
                ],
                relativeTime: pulseTime
            )
        }

        return (events, (times.last ?? initialDelay) - initialDelay)
    }
}
