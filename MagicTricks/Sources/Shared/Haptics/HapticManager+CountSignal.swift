//
//  HapticManager+CountSignal.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import CoreHaptics
import UIKit

extension HapticManager {

    // MARK: - Engine / Scheduler forwarding

    func restartEngineIfNeeded() {
        enginePlayer.restartEngineIfNeeded()
    }

    func schedule(after delay: TimeInterval, action: @escaping Completion) {
        scheduler.schedule(after: delay, action: action)
    }

    func scheduleCompletion(
        initialDelay: TimeInterval,
        signalDuration: TimeInterval,
        completion: Completion?
    ) {
        scheduler.scheduleCompletion(
            initialDelay: initialDelay,
            signalDuration: signalDuration,
            completion: completion
        )
    }

    func playCoreHapticEvents(_ events: [CHHapticEvent], fallback: Completion) {
        enginePlayer.playEvents(events, fallback: fallback)
    }

    // MARK: - Count signal

    func playCountSignal(
        _ count: Int,
        initialDelay: TimeInterval = HapticTiming.initialDelay,
        generator: UIImpactFeedbackGenerator,
        timings: HapticTimings,
        completion: Completion? = nil
    ) {
        guard count > 0 else {
            playZeroBuzz(initialDelay: initialDelay, generator: generator, timings: timings, completion: completion)
            return
        }
        scheduler.scheduleImpactSequence(
            count: count,
            initialDelay: initialDelay,
            interval: timings.pulseGap,
            generator: generator,
            completion: completion
        )
    }

    // MARK: - Grouped count signal

    func playGroupedCountSignal(
        _ count: Int,
        initialDelay: TimeInterval = HapticTiming.initialDelay,
        generator: UIImpactFeedbackGenerator,
        timings: HapticTimings,
        completion: Completion? = nil
    ) {
        guard count > 0 else {
            playZeroBuzz(initialDelay: initialDelay, generator: generator, timings: timings, completion: completion)
            return
        }

        let chunkSize = HapticTiming.groupedChunkSize
        var time = initialDelay
        var remaining = count

        var isFirstGroup = true

        while remaining > 0 {
            let groupCount = min(chunkSize, remaining)
            let isLastGroup = remaining == groupCount
            let pulseGap = groupCount < chunkSize
                ? timings.grouped.remainderPulseGap
                : timings.grouped.pulseGap

            if !isFirstGroup {
                let prepareTime = max(time - 0.1, 0)
                scheduler.schedule(after: prepareTime) { generator.prepare() }
            }

            scheduler.scheduleImpactSequence(
                count: groupCount,
                initialDelay: time,
                interval: pulseGap,
                generator: generator,
                completion: isLastGroup ? completion : nil
            )

            time += Double(groupCount - 1) * pulseGap + timings.grouped.groupGap
            remaining -= groupCount
            isFirstGroup = false
        }
    }

    // MARK: - Zero buzz

    private func playZeroBuzz(
        initialDelay: TimeInterval,
        generator: UIImpactFeedbackGenerator,
        timings: HapticTimings,
        completion: Completion?
    ) {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: timings.intensity.coreHapticsValue),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
            ],
            relativeTime: initialDelay,
            duration: timings.longDuration
        )
        enginePlayer.playEvents([event]) {
            self.scheduler.scheduleImpact(using: generator, after: initialDelay, intensity: timings.intensity.impactIntensity)
        }
        scheduler.scheduleCompletion(
            initialDelay: initialDelay,
            signalDuration: timings.longDuration,
            completion: completion
        )
    }
}
