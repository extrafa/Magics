//
//  GroupedHapticPatternBuilderTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

final class GroupedHapticPatternBuilderTests: XCTestCase {

    // speed 1.0 lands in the slowest grouped tier: pulseGap 0.15, remainderPulseGap 0.19, groupGap 0.53.
    private let timings = HapticTimings(preferences: MockHapticPreferences(speed: 1.0))

    private func times(_ count: Int, initialDelay: TimeInterval = 0) -> [TimeInterval] {
        GroupedHapticPatternBuilder
            .groupedCountEvents(count: count, initialDelay: initialDelay, timings: timings)
            .events.map(\.relativeTime)
    }

    private func assertTimes(_ actual: [TimeInterval], _ expected: [TimeInterval], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.count, expected.count, file: file, line: line)
        for (a, e) in zip(actual, expected) {
            XCTAssertEqual(a, e, accuracy: 0.0001, file: file, line: line)
        }
    }

    func test_sevenPulses_splitIntoGroupsOfThreeThreeAndOne() {
        assertTimes(times(7), [0, 0.15, 0.30, 0.83, 0.98, 1.13, 1.66])
    }

    func test_exactMultipleOfGroupSize_usesOnlyFullGroupPulseGap() {
        assertTimes(times(3), [0, 0.15, 0.30])
    }

    func test_incompleteGroup_usesRemainderPulseGap() {
        assertTimes(times(5), [0, 0.15, 0.30, 0.83, 1.02])
    }

    func test_singlePulse_hasZeroDuration() {
        let result = GroupedHapticPatternBuilder.groupedCountEvents(count: 1, initialDelay: 0, timings: timings)

        XCTAssertEqual(result.events.count, 1)
        XCTAssertEqual(result.duration, 0, accuracy: 0.0001)
    }

    func test_duration_isLastPulseTimeMinusInitialDelay() {
        let result = GroupedHapticPatternBuilder.groupedCountEvents(count: 7, initialDelay: 0.5, timings: timings)

        XCTAssertEqual(result.duration, 1.66, accuracy: 0.0001)
    }

    func test_initialDelay_shiftsEveryPulse() {
        assertTimes(times(4, initialDelay: 0.5), [0.5, 0.65, 0.80, 1.33])
    }
}

private struct MockHapticPreferences: HapticPreferenceManaging {
    var hapticSpeedMultiplier: Double
    var isHapticGroupByThreeEnabled = true
    var hapticIntensity: HapticIntensity = .heavy

    init(speed: Double) {
        hapticSpeedMultiplier = speed
    }

    func resetHapticSettings() {}
}
