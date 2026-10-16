//
//  HapticManagerTests.swift
//  MagicTricksTests
//
//  Created by Ross on 02/06/2026.
//

import CoreHaptics
import SwiftUI
import UIKit
import XCTest
@testable import MagicTricks

@MainActor
final class HapticManagerTests: XCTestCase {

    func test_handleScenePhase_activeRestartsInjectedEngine() {
        let engine = MockHapticEnginePlayer()
        let manager = HapticManager(enginePlayer: engine, scheduler: MockHapticScheduler())

        manager.handleScenePhase(.active)

        XCTAssertEqual(engine.restartCount, 1)
    }

    func test_handleScenePhase_inactiveDoesNotRestartInjectedEngine() {
        let engine = MockHapticEnginePlayer()
        let manager = HapticManager(enginePlayer: engine, scheduler: MockHapticScheduler())

        manager.handleScenePhase(.inactive)

        XCTAssertEqual(engine.restartCount, 0)
    }

    func test_playCoreHapticEvents_usesInjectedEngineAndFallback() {
        let engine = MockHapticEnginePlayer()
        engine.shouldRunFallback = true
        let manager = HapticManager(enginePlayer: engine, scheduler: MockHapticScheduler())
        var didRunFallback = false

        manager.playCoreHapticEvents([]) {
            didRunFallback = true
        }

        XCTAssertEqual(engine.playEventsCount, 1)
        XCTAssertTrue(didRunFallback)
    }

    func test_playGroupedCountSignal_callsCompletionOnceAfterLastPulse() {
        let scheduler = MockHapticScheduler()
        let manager = HapticManager(enginePlayer: MockHapticEnginePlayer(), scheduler: scheduler)
        var completionCount = 0

        manager.playGroupedCountSignal(
            7,
            initialDelay: 0.5,
            generator: UIImpactFeedbackGenerator(),
            timings: HapticTimings(preferences: MockHapticPreferences()),
            completion: { completionCount += 1 }
        )

        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(scheduler.scheduledDelays.count, 1)
        XCTAssertEqual(scheduler.scheduledDelays[0], 0.5 + 1.66, accuracy: 0.0001)
    }

    func test_playGroupedCountSignal_whenEngineFallsBack_stillCallsCompletionOnce() {
        let engine = MockHapticEnginePlayer()
        engine.shouldRunFallback = true
        let manager = HapticManager(enginePlayer: engine, scheduler: MockHapticScheduler())
        var completionCount = 0

        manager.playGroupedCountSignal(
            7,
            generator: UIImpactFeedbackGenerator(),
            timings: HapticTimings(preferences: MockHapticPreferences()),
            completion: { completionCount += 1 }
        )

        XCTAssertEqual(completionCount, 1)
    }
}

private struct MockHapticPreferences: HapticPreferenceManaging {
    var hapticSpeedMultiplier = 1.0
    var isHapticGroupByThreeEnabled = true
    var hapticIntensity: HapticIntensity = .heavy

    func resetHapticSettings() {}
}

@MainActor
private final class MockHapticEnginePlayer: HapticEnginePlaying {
    var restartCount = 0
    var playEventsCount = 0
    var shouldRunFallback = false

    func restartEngineIfNeeded() {
        restartCount += 1
    }

    func playEvents(_ events: [CHHapticEvent], fallback: () -> Void) {
        playEventsCount += 1

        if shouldRunFallback {
            fallback()
        }
    }

    func stop() {}

    func stopEngine() {}
}

@MainActor
private final class MockHapticScheduler: HapticScheduling {
    var scheduledDelays: [TimeInterval] = []

    func schedule(after delay: TimeInterval, action: @escaping () -> Void) {
        scheduledDelays.append(delay)
        action()
    }

    func cancelAll() {}

    func scheduleCompletion(
        initialDelay: TimeInterval,
        signalDuration: TimeInterval,
        completion: (() -> Void)?
    ) {
        completion?()
    }

    func scheduleImpact(
        using generator: UIImpactFeedbackGenerator,
        after delay: TimeInterval,
        intensity: CGFloat?
    ) {}

    func scheduleImpactSequence(
        count: Int,
        initialDelay: TimeInterval,
        interval: TimeInterval,
        generator: UIImpactFeedbackGenerator,
        completion: (() -> Void)?
    ) {
        completion?()
    }

    func scheduleTimeDigit(
        _ digit: Int,
        startTime: TimeInterval,
        generator: UIImpactFeedbackGenerator
    ) -> TimeInterval {
        startTime
    }
}
