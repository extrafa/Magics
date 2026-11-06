//
//  GroupedHapticPatternBuilder.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import CoreHaptics
import Foundation

enum GroupedHapticPatternBuilder {
    static func groupedCountEvents(
        count: Int,
        initialDelay: TimeInterval,
        timings: HapticTimings
    ) -> (events: [CHHapticEvent], duration: TimeInterval) {
        let intensity = timings.intensity.coreHapticsValue
        let chunkSize = HapticTiming.groupedChunkSize

        var events: [CHHapticEvent] = []
        var time = initialDelay
        var lastPulseTime = initialDelay
        var remaining = count

        while remaining > 0 {
            let groupCount = min(chunkSize, remaining)
            let pulseGap = groupCount < chunkSize
                ? timings.grouped.remainderPulseGap
                : timings.grouped.pulseGap

            for index in 0..<groupCount {
                let pulseTime = time + Double(index) * pulseGap
                events.append(
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
                        ],
                        relativeTime: pulseTime
                    )
                )
                lastPulseTime = pulseTime
            }

            time += Double(groupCount - 1) * pulseGap + timings.grouped.groupGap
            remaining -= groupCount
        }

        return (events, lastPulseTime - initialDelay)
    }
}
