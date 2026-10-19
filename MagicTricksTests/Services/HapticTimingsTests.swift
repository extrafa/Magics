//
//  HapticTimingsTests.swift
//  MagicTricksTests
//
//  Created by Ross on 31/08/2026.
//

import XCTest
@testable import MagicTricks

final class HapticTimingsTests: XCTestCase {

    func test_digitGap_shrinksAsSpeedIncreases() {
        let slow = HapticTimings(preferences: MockHapticPreferences(speed: 1.0))
        let fast = HapticTimings(preferences: MockHapticPreferences(speed: 2.5))

        XCTAssertLessThan(fast.digitGap, slow.digitGap)
    }

    func test_pulseGap_shrinksAsSpeedIncreases() {
        let slow = HapticTimings(preferences: MockHapticPreferences(speed: 1.0))
        let fast = HapticTimings(preferences: MockHapticPreferences(speed: 2.5))

        XCTAssertLessThan(fast.pulseGap, slow.pulseGap)
    }

    func test_intensity_comesFromInjectedPreferences() {
        let timings = HapticTimings(preferences: MockHapticPreferences(speed: 1.5, intensity: .light))

        XCTAssertEqual(timings.intensity, .light)
    }
}
