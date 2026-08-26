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
}

@MainActor
private final class MockHapticScheduler: HapticScheduling {
    func schedule(after delay: TimeInterval, action: @escaping () -> Void) {
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
