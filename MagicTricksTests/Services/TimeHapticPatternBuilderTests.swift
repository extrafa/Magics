//
//  TimeHapticPatternBuilderTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

final class TimeHapticPatternBuilderTests: XCTestCase {

    // speed 1.0 keeps every scaled timing at its base value: pulseGap 0.32,
    // digitGap 1.15, zeroDuration (longDuration) 0.55.
    private let timings = HapticTimings(preferences: MockHapticPreferences(speed: 1.0))

    func test_timeValueEvents_singleDigitZeros_placesOneContinuousEventPerDigit() {
        let events = TimeHapticPatternBuilder.timeValueEvents(tens: 0, ones: 0, initialDelay: 0, timings: timings)

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].relativeTime, 0)
        XCTAssertEqual(events[1].relativeTime, 1.70, accuracy: 0.0001)
    }

    func test_timeValueEvents_multiDigitTens_placesTransientPulsesThenOnesDigit() {
        let events = TimeHapticPatternBuilder.timeValueEvents(tens: 3, ones: 0, initialDelay: 0, timings: timings)

        XCTAssertEqual(events.count, 4)
        XCTAssertEqual(events[0].relativeTime, 0)
        XCTAssertEqual(events[1].relativeTime, 0.32, accuracy: 0.0001)
        XCTAssertEqual(events[2].relativeTime, 0.64, accuracy: 0.0001)
        XCTAssertEqual(events[3].relativeTime, 1.79, accuracy: 0.0001)
    }

    func test_timeValueEvents_respectsInitialDelay() {
        let events = TimeHapticPatternBuilder.timeValueEvents(tens: 0, ones: 0, initialDelay: 0.5, timings: timings)

        XCTAssertEqual(events[0].relativeTime, 0.5, accuracy: 0.0001)
    }

    func test_fallbackDigitImpactTimes_zero_returnsSingleStartTime() {
        let times = TimeHapticPatternBuilder.fallbackDigitImpactTimes(0, startTime: 1.0, timings: timings)

        XCTAssertEqual(times, [1.0])
    }

    func test_fallbackDigitImpactTimes_nonZero_spacesPulsesByPulseGap() {
        let times = TimeHapticPatternBuilder.fallbackDigitImpactTimes(3, startTime: 0, timings: timings)
        let expected: [TimeInterval] = [0, 0.32, 0.64]

        XCTAssertEqual(times.count, expected.count)
        for (time, expectedTime) in zip(times, expected) {
            XCTAssertEqual(time, expectedTime, accuracy: 0.0001)
        }
    }

    func test_nextDigitStartTime_zero_advancesByZeroDuration() {
        let next = TimeHapticPatternBuilder.nextDigitStartTime(0, startTime: 0, timings: timings)

        XCTAssertEqual(next, timings.zeroDuration, accuracy: 0.0001)
    }

    func test_nextDigitStartTime_nonZero_advancesByDigitDuration() {
        let next = TimeHapticPatternBuilder.nextDigitStartTime(3, startTime: 0, timings: timings)

        XCTAssertEqual(next, 0.64, accuracy: 0.0001)
    }
}

private struct MockHapticPreferences: HapticPreferenceManaging {
    var hapticSpeedMultiplier: Double
    var isHapticGroupByThreeEnabled = false
    var hapticIntensity: HapticIntensity = .heavy

    init(speed: Double) {
        hapticSpeedMultiplier = speed
    }

    func resetHapticSettings() {}
}
