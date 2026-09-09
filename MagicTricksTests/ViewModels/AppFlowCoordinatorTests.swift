//
//  AppFlowCoordinatorTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class AppFlowCoordinatorTests: XCTestCase {

    private let trick = TrickCollection.tricks[0]

    func test_recordTrickClose_threeTimes_showsRateAppSheet() {
        let coordinator = AppFlowCoordinator(
            preferences: AppPreferences(store: MockPreferenceStore()),
            scheduler: ImmediateScheduler()
        )

        coordinator.recordTrickClose()
        coordinator.recordTrickClose()
        XCTAssertNil(coordinator.activeSheet)

        coordinator.recordTrickClose()

        XCTAssertEqual(coordinator.activeSheet, .rateApp)
    }

    func test_recordTrickClose_whenAlreadyResponded_doesNotIncrementOrShowSheet() {
        let store = MockPreferenceStore()
        let preferences = AppPreferences(store: store)
        preferences.hasRespondedToRating = true
        let coordinator = AppFlowCoordinator(preferences: preferences, scheduler: ImmediateScheduler())

        coordinator.recordTrickClose()
        coordinator.recordTrickClose()
        coordinator.recordTrickClose()

        XCTAssertEqual(preferences.trickLaunchCount, 0)
        XCTAssertNil(coordinator.activeSheet)
    }

    func test_openStartFlow_forUnseenTrick_showsInstructionFirstLaunch() {
        let coordinator = AppFlowCoordinator(preferences: AppPreferences(store: MockPreferenceStore()))

        coordinator.openStartFlow(for: trick)

        XCTAssertEqual(
            coordinator.activeSheet,
            .instructionFirstLaunch(instruction: trick.instruction, trick: trick)
        )
    }

    func test_openStartFlow_forSeenTrick_opensTrickDirectly() {
        let coordinator = AppFlowCoordinator(preferences: AppPreferences(store: MockPreferenceStore()))
        coordinator.markTrickAsSeen(trick)

        coordinator.openStartFlow(for: trick)

        XCTAssertEqual(coordinator.activeFlow, .trick(trick: trick))
    }
}

private final class ImmediateScheduler: DelayedActionScheduling {
    func schedule(after delay: TimeInterval, action: @escaping Completion) {
        action()
    }
}

private final class MockPreferenceStore: PreferenceStoring {
    var storage: [String: Any] = [:]

    func object(forKey defaultName: String) -> Any? { storage[defaultName] }
    func bool(forKey defaultName: String) -> Bool { (storage[defaultName] as? Bool) ?? false }
    func double(forKey defaultName: String) -> Double { (storage[defaultName] as? Double) ?? 0 }
    func stringArray(forKey defaultName: String) -> [String]? { storage[defaultName] as? [String] }
    func set(_ value: Any?, forKey defaultName: String) { storage[defaultName] = value }
}
