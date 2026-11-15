//
//  GroupedHapticPatternBuilderTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

final class GroupedHapticPatternBuilderTests: XCTestCase {

    // speed 1.0 lands in the slowest grouped tier: pulseGap 0.15, remainderPulseGap 0.19, groupGap 0.53.
    private let timings = HapticTimings(preferences: MockHapticPreferences(speed: 1.0, groupByThree: true))

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

    func test_pulseTimes_followTheSameClockAsTheEvents() {
        for count in [0, 1, 3, 5, 7, 10] {
            let pulseTimes = GroupedHapticPatternBuilder.pulseTimes(count: count, initialDelay: 0.5, timings: timings)

            assertTimes(pulseTimes, times(count, initialDelay: 0.5))
        }
    }

    func test_pulseTimes_ofSeven_startAtZeroAndGroupByThree() {
        let pulseTimes = GroupedHapticPatternBuilder.pulseTimes(count: 7, initialDelay: 0, timings: timings)

        assertTimes(pulseTimes, [0, 0.15, 0.30, 0.83, 0.98, 1.13, 1.66])
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

final class GroupingDemoTimelineTests: XCTestCase {

    func test_everyPulseLightsItsDot_thenTheDotGoesBackDown() {
        let steps = GroupingDemoTimeline.steps(pulseTimes: [0, 0.5, 1.0], holdDuration: 0.09)

        XCTAssertEqual(steps.map(\.activeDot), [0, nil, 1, nil, 2, nil])
        XCTAssertEqual(steps.map(\.time), [0, 0.09, 0.5, 0.59, 1.0, 1.09])
    }

    func test_closePulses_putTheDotDownBeforeTheNextOne() {
        // The fastest grouped gap is 0.10 s: a 0.09 s hold would leave no pause.
        let steps = GroupingDemoTimeline.steps(pulseTimes: [0, 0.10], holdDuration: 0.09)

        XCTAssertEqual(steps[1].time, 0.06, accuracy: 0.0001)
        XCTAssertLessThan(steps[1].time, steps[2].time)
    }

    func test_stepTimes_neverGoBackwards() {
        let pulseTimes = GroupedHapticPatternBuilder.pulseTimes(
            count: 7,
            initialDelay: 0,
            timings: HapticTimings(preferences: MockHapticPreferences(speed: 2.25, groupByThree: true))
        )
        let times = GroupingDemoTimeline.steps(pulseTimes: pulseTimes).map(\.time)

        XCTAssertEqual(times, times.sorted())
    }
}
