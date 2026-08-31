//
//  HapticScheduler.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation
import UIKit

@MainActor
final class HapticScheduler {
    private let preferences: HapticPreferenceManaging
    private var generation = 0

    init(preferences: HapticPreferenceManaging = AppPreferences.shared) {
        self.preferences = preferences
    }

    func schedule(after delay: TimeInterval, action: @escaping Completion) {
        let scheduledGeneration = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard self?.generation == scheduledGeneration else { return }
            action()
        }
    }

    func cancelAll() {
        generation += 1
    }

    func scheduleCompletion(
        initialDelay: TimeInterval,
        signalDuration: TimeInterval,
        completion: Completion?
    ) {
        schedule(after: initialDelay + signalDuration + HapticTiming.completionPadding) {
            completion?()
        }
    }

    func scheduleImpact(
        using generator: UIImpactFeedbackGenerator,
        after delay: TimeInterval,
        intensity: CGFloat? = nil
    ) {
        schedule(after: delay) {
            generator.impactOccurred(intensity: intensity ?? self.preferences.hapticIntensity.impactIntensity)
            generator.prepare()
        }
    }

    func scheduleImpactSequence(
        count: Int,
        initialDelay: TimeInterval,
        interval: TimeInterval,
        generator: UIImpactFeedbackGenerator,
        completion: Completion?
    ) {
        guard count > 0 else {
            completion?()
            return
        }

        let intensity = preferences.hapticIntensity.impactIntensity
        generator.prepare()

        for index in 0..<count {
            let isLast = index == count - 1
            schedule(after: initialDelay + Double(index) * interval) {
                generator.impactOccurred(intensity: intensity)
                if !isLast { generator.prepare() }
                if isLast { completion?() }
            }
        }
    }

    func scheduleTimeDigit(
        _ digit: Int,
        startTime: TimeInterval,
        generator: UIImpactFeedbackGenerator
    ) -> TimeInterval {
        let timings = HapticTimings(preferences: preferences)
        for pulseTime in TimeHapticPatternBuilder.fallbackDigitImpactTimes(digit, startTime: startTime, timings: timings) {
            scheduleImpact(using: generator, after: pulseTime)
        }

        return TimeHapticPatternBuilder.nextDigitStartTime(digit, startTime: startTime, timings: timings)
    }
}

extension HapticScheduler: HapticScheduling {}
