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
    func schedule(after delay: TimeInterval, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            action()
        }
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
            if let intensity {
                generator.impactOccurred(intensity: intensity)
            } else {
                generator.impactOccurred()
            }
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

        generator.prepare()

        for index in 0..<count {
            let isLast = index == count - 1
            schedule(after: initialDelay + Double(index) * interval) {
                generator.impactOccurred()
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
            scheduleImpact(
                using: generator,
                after: pulseTime,
                intensity: digit == 0 ? 1 : nil
            )
        }

        return TimeHapticPatternBuilder.nextDigitStartTime(digit, startTime: startTime)
    }
}

extension HapticScheduler: HapticScheduling {}
