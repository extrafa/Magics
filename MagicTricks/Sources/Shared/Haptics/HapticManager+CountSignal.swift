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

    func schedule(after delay: TimeInterval, action: @escaping () -> Void) {
        scheduler.schedule(after: delay, action: action)
    }

    func scheduleCompletion(
        initialDelay: TimeInterval,
        signalDuration: TimeInterval,
        completion: (() -> Void)?
    ) {
        scheduler.scheduleCompletion(
            initialDelay: initialDelay,
            signalDuration: signalDuration,
            completion: completion
        )
    }

    func playCoreHapticEvents(_ events: [CHHapticEvent], fallback: () -> Void) {
        enginePlayer.playEvents(events, fallback: fallback)
    }

    // MARK: - Count signal

    func playCountSignal(
        _ count: Int,
        initialDelay: TimeInterval = HapticTiming.initialDelay,
        generator: UIImpactFeedbackGenerator,
        completion: (() -> Void)? = nil
    ) {
        guard count > 0 else {
            playZeroBuzz(initialDelay: initialDelay, generator: generator, completion: completion)
            return
        }
        scheduler.scheduleImpactSequence(
            count: count,
            initialDelay: initialDelay,
            interval: HapticPreferences.pulseGap,
            generator: generator,
            completion: completion
        )
    }

    // MARK: - Grouped count signal

    func playGroupedCountSignal(
        _ count: Int,
        initialDelay: TimeInterval = HapticTiming.initialDelay,
        generator: UIImpactFeedbackGenerator,
        completion: (() -> Void)? = nil
    ) {
        guard count > 0 else {
            playZeroBuzz(initialDelay: initialDelay, generator: generator, completion: completion)
            return
        }

        let chunkSize = HapticPreferences.groupedChunkSize
        var time = initialDelay
        var remaining = count

        var isFirstGroup = true

        while remaining > 0 {
            let groupCount = min(chunkSize, remaining)
            let isLastGroup = remaining == groupCount
            let pulseGap = groupCount < chunkSize
                ? HapticPreferences.groupedRemainderPulseGap
                : HapticPreferences.groupedPulseGap

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

            time += Double(groupCount - 1) * pulseGap + HapticPreferences.groupedGroupGap
            remaining -= groupCount
            isFirstGroup = false
        }
    }

    // MARK: - Zero buzz

    private func playZeroBuzz(
        initialDelay: TimeInterval,
        generator: UIImpactFeedbackGenerator,
        completion: (() -> Void)?
    ) {
        // 0 is a long continuous buzz, not a transient tap
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: HapticPreferences.intensity.coreHapticsValue),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
            ],
            relativeTime: initialDelay,
            duration: HapticPreferences.longDuration
        )
        enginePlayer.playEvents([event]) {
            // Fallback if CoreHaptics unavailable
            self.scheduler.scheduleImpact(using: generator, after: initialDelay, intensity: nil)
        }
        scheduler.scheduleCompletion(
            initialDelay: initialDelay,
            signalDuration: HapticPreferences.longDuration,
            completion: completion
        )
    }
}
