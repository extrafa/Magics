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

final class GroupingDemoClockTests: XCTestCase {

    private let pulseTimes: [TimeInterval] = [0, 0.1, 0.2, 0.56, 0.66, 0.76, 1.12]

    func test_nothingHasFiredBeforeTheFirstPulse() {
        XCTAssertEqual(GroupingDemoClock.firedPulses(pulseTimes: pulseTimes, elapsed: -0.01), 0)
    }

    func test_pulsesCountAsFiredFromTheirOwnTime() {
        XCTAssertEqual(GroupingDemoClock.firedPulses(pulseTimes: pulseTimes, elapsed: 0), 1)
        XCTAssertEqual(GroupingDemoClock.firedPulses(pulseTimes: pulseTimes, elapsed: 0.2), 3)
        XCTAssertEqual(GroupingDemoClock.firedPulses(pulseTimes: pulseTimes, elapsed: 0.56), 4)
    }

    func test_aLateWakeUp_catchesUpOnEveryPulseItMissed() {
        // The screen woke 0.3 s late, right across the start of the second group: no dot is skipped.
        XCTAssertEqual(GroupingDemoClock.firedPulses(pulseTimes: pulseTimes, elapsed: 0.7), 5)
    }

    func test_afterTheLastPulse_allSevenHaveFired() {
        XCTAssertEqual(GroupingDemoClock.firedPulses(pulseTimes: pulseTimes, elapsed: 5), 7)
    }
}

final class PulseDotMemoryTests: XCTestCase {

    func test_aDotJumpsOnceWhenItsPulseIsReached() {
        var memory = PulseDotMemory()

        XCTAssertFalse(memory.shouldJump(index: 2, progress: GroupingDemoProgress(run: 1, fired: 2)))
        XCTAssertTrue(memory.shouldJump(index: 2, progress: GroupingDemoProgress(run: 1, fired: 3)))
        XCTAssertFalse(memory.shouldJump(index: 2, progress: GroupingDemoProgress(run: 1, fired: 4)))
    }

    func test_aDotJumpsEvenWhenTheScreenSawSeveralPulsesAtOnce() {
        var memory = PulseDotMemory()

        XCTAssertTrue(memory.shouldJump(index: 3, progress: GroupingDemoProgress(run: 1, fired: 5)))
    }

    func test_aReplayThatStartsBeforeTheScreenSawZero_stillMakesEveryDotJumpAgain() {
        var memory = PulseDotMemory()
        XCTAssertTrue(memory.shouldJump(index: 0, progress: GroupingDemoProgress(run: 1, fired: 7)))

        // The second run goes from 7 pulses straight to 1: the new run number tells the dot to start over.
        XCTAssertTrue(memory.shouldJump(index: 0, progress: GroupingDemoProgress(run: 2, fired: 1)))
        XCTAssertFalse(memory.shouldJump(index: 0, progress: GroupingDemoProgress(run: 2, fired: 2)))
    }
}
