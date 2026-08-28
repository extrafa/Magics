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
    private var generation = 0

    func schedule(after delay: TimeInterval, action: @escaping () -> Void) {
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
        completion: (() -> Void)?
    ) {
        schedule(after: initialDelay + signalDuration + HapticPreferences.completionPadding) {
            completion?()
        }
    }

    func scheduleImpact(
        using generator: UIImpactFeedbackGenerator,
        after delay: TimeInterval,
        intensity: CGFloat? = nil
    ) {
        schedule(after: delay) {
            generator.impactOccurred(intensity: intensity ?? HapticPreferences.intensity.impactIntensity)
            generator.prepare()
        }
    }

    func scheduleImpactSequence(
        count: Int,
        initialDelay: TimeInterval,
        interval: TimeInterval,
        generator: UIImpactFeedbackGenerator,
        completion: (() -> Void)?
    ) {
        guard count > 0 else {
            completion?()
            return
        }

        let intensity = HapticPreferences.intensity.impactIntensity
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
        for pulseTime in TimeHapticPatternBuilder.fallbackDigitImpactTimes(digit, startTime: startTime) {
            scheduleImpact(using: generator, after: pulseTime)
        }

        return TimeHapticPatternBuilder.nextDigitStartTime(digit, startTime: startTime)
    }
}

extension HapticScheduler: HapticScheduling {}
