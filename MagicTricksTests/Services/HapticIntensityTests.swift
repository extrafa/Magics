//
//  HapticIntensityTests.swift
//  MagicTricksTests
//

import CoreHaptics
import UIKit
import XCTest
@testable import MagicTricks

@MainActor
final class HapticIntensityTests: XCTestCase {

    func test_impactIntensity_stepsUpFromWeakToStrong() {
        XCTAssertEqual(HapticIntensity.light.impactIntensity, 1.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(HapticIntensity.medium.impactIntensity, 2.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(HapticIntensity.heavy.impactIntensity, 1.0, accuracy: 0.0001)
    }

    func test_coreHapticsValue_stepsUpFromWeakToStrong_andNeverExceedsOne() {
        XCTAssertEqual(HapticIntensity.light.coreHapticsValue, 0.45, accuracy: 0.0001)
        XCTAssertEqual(HapticIntensity.medium.coreHapticsValue, 0.7, accuracy: 0.0001)
        XCTAssertEqual(HapticIntensity.heavy.coreHapticsValue, 1.0, accuracy: 0.0001)
    }

    func test_groupedCountEvents_carryTheIntensityOfThePreference() {
        for intensity in HapticIntensity.allCases {
            let timings = HapticTimings(preferences: MockHapticPreferences(speed: 1.0, groupByThree: true, intensity: intensity))

            let events = GroupedHapticPatternBuilder.groupedCountEvents(count: 5, initialDelay: 0, timings: timings).events

            XCTAssertFalse(events.isEmpty)
            for event in events {
                XCTAssertEqual(Self.intensity(of: event), intensity.coreHapticsValue, accuracy: 0.0001)
            }
        }
    }

    func test_timeValueEvents_carryTheIntensityOfThePreference_forPulsesAndForZero() {
        for intensity in HapticIntensity.allCases {
            let timings = HapticTimings(preferences: MockHapticPreferences(speed: 1.0, intensity: intensity))

            let events = TimeHapticPatternBuilder.timeValueEvents(tens: 0, ones: 3, initialDelay: 0, timings: timings)

            XCTAssertEqual(events.count, 4)
            for event in events {
                XCTAssertEqual(Self.intensity(of: event), intensity.coreHapticsValue, accuracy: 0.0001)
            }
        }
    }

    func test_scheduler_playsImpactsAtTheIntensityOfThePreference() async {
        for intensity in HapticIntensity.allCases {
            let generator = RecordingImpactGenerator()
            let scheduler = HapticScheduler(preferences: MockHapticPreferences(intensity: intensity))
            let finished = expectation(description: "sequence finished for \(intensity)")

            scheduler.scheduleImpactSequence(
                count: 2,
                initialDelay: 0,
                interval: 0.01,
                generator: generator,
                completion: { finished.fulfill() }
            )
            await fulfillment(of: [finished], timeout: 2)

            XCTAssertEqual(generator.intensities.count, 2)
            for value in generator.intensities {
                XCTAssertEqual(value, intensity.impactIntensity, accuracy: 0.0001)
            }
        }
    }

    private static func intensity(of event: CHHapticEvent) -> Float {
        event.eventParameters.first { $0.parameterID == .hapticIntensity }?.value ?? -1
    }
}

@MainActor
private final class RecordingImpactGenerator: UIImpactFeedbackGenerator {
    private(set) var intensities: [CGFloat] = []

    override func impactOccurred(intensity: CGFloat) {
        intensities.append(intensity)
    }
}
