//
//  HapticProtocols.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import CoreHaptics
import Foundation
import UIKit

@MainActor
protocol HapticEnginePlaying {
    func restartEngineIfNeeded()
    func playEvents(_ events: [CHHapticEvent], fallback: Completion)
    func stop()
}

@MainActor
protocol HapticScheduling {
    func schedule(after delay: TimeInterval, action: @escaping Completion)
    func cancelAll()
    func scheduleCompletion(
        initialDelay: TimeInterval,
        signalDuration: TimeInterval,
        completion: Completion?
    )
    func scheduleImpact(
        using generator: UIImpactFeedbackGenerator,
        after delay: TimeInterval,
        intensity: CGFloat?
    )
    func scheduleImpactSequence(
        count: Int,
        initialDelay: TimeInterval,
        interval: TimeInterval,
        generator: UIImpactFeedbackGenerator,
        completion: Completion?
    )
    func scheduleTimeDigit(
        _ digit: Int,
        startTime: TimeInterval,
        generator: UIImpactFeedbackGenerator
    ) -> TimeInterval
}

@MainActor
protocol HapticEngineManaging {
    func restartEngineIfNeeded()
}

@MainActor
protocol HapticNotificationPlaying {
    func playSuccessNotification()
}

@MainActor
protocol CountHapticPlaying {
    func playCount(_ count: Int, completion: Completion?)
    func cancelPendingHaptics()
}

@MainActor
protocol TimeHapticPlaying {
    func playTimeValue(
        _ value: Int,
        initialDelay: TimeInterval,
        usesGrouping: Bool,
        completion: Completion?
    )
    func cancelPendingHaptics()
}
