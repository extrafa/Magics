//
//  AppFlowCoordinatorTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class AppFlowCoordinatorTests: XCTestCase {

    private let trick = TrickCollection.tricks[0]
    private let proTrick = TrickCollection.tricks.first { $0.id.requiresPro }!

    private func makeCoordinator() -> AppFlowCoordinator {
        AppFlowCoordinator(
            store: StoreManager(defaults: MockPreferenceStore()),
            preferences: AppPreferences(store: MockPreferenceStore()),
            scheduler: ImmediateScheduler()
        )
    }

    func test_openPaywall_withoutContext_isGeneral() {
        let coordinator = makeCoordinator()

        coordinator.openPaywall()

        XCTAssertEqual(coordinator.activeFlow, .paywall(context: .general))
    }

    func test_openInstruction_forLockedTrick_opensPaywallForThatTrick() {
        let coordinator = makeCoordinator()

        coordinator.open(instruction: proTrick)

        XCTAssertEqual(coordinator.activeFlow, .paywall(context: .trick(proTrick.id)))
        XCTAssertNil(coordinator.activeSheet)
    }

    func test_openStartFlow_forLockedTrick_opensPaywallForThatTrick() {
        let coordinator = makeCoordinator()

        coordinator.openStartFlow(for: proTrick)

        XCTAssertEqual(coordinator.activeFlow, .paywall(context: .trick(proTrick.id)))
    }

    func test_paywallFlowIDs_differPerContext() {
        let ids = [
            FullScreenFlow.paywall(context: .general).id,
            FullScreenFlow.paywall(context: .trick(.phantomDraw)).id,
            FullScreenFlow.paywall(context: .trick(.colorSense)).id
        ]

        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func test_recordTrickClose_threeTimes_showsRateAppSheet() {
        let coordinator = AppFlowCoordinator(
            store: StoreManager(defaults: MockPreferenceStore()),
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
        let coordinator = AppFlowCoordinator(
            store: StoreManager(defaults: MockPreferenceStore()),
            preferences: preferences,
            scheduler: ImmediateScheduler()
        )

        coordinator.recordTrickClose()
        coordinator.recordTrickClose()
        coordinator.recordTrickClose()

        XCTAssertEqual(preferences.trickLaunchCount, 0)
        XCTAssertNil(coordinator.activeSheet)
    }

    func test_recordTrickClose_whenSnoozed_doesNotIncrementOrShowSheet() {
        let store = MockPreferenceStore()
        let preferences = AppPreferences(store: store)
        preferences.ratingSnoozedUntil = Date().addingTimeInterval(3600)
        let coordinator = AppFlowCoordinator(
            store: StoreManager(defaults: MockPreferenceStore()),
            preferences: preferences,
            scheduler: ImmediateScheduler()
        )

        coordinator.recordTrickClose()
        coordinator.recordTrickClose()
        coordinator.recordTrickClose()

        XCTAssertEqual(preferences.trickLaunchCount, 0)
        XCTAssertNil(coordinator.activeSheet)
    }

    func test_resetRatingState_clearsSnooze() {
        let store = MockPreferenceStore()
        let preferences = AppPreferences(store: store)
        preferences.hasRespondedToRating = true
        preferences.trickLaunchCount = 2
        preferences.ratingSnoozedUntil = Date().addingTimeInterval(3600)
        let coordinator = AppFlowCoordinator(
            store: StoreManager(defaults: MockPreferenceStore()),
            preferences: preferences,
            scheduler: ImmediateScheduler()
        )

        coordinator.resetRatingState()

        XCTAssertFalse(preferences.hasRespondedToRating)
        XCTAssertEqual(preferences.trickLaunchCount, 0)
        XCTAssertNil(preferences.ratingSnoozedUntil)

        coordinator.recordTrickClose()
        coordinator.recordTrickClose()
        coordinator.recordTrickClose()

        XCTAssertEqual(coordinator.activeSheet, .rateApp)
    }

    func test_recordTrickClose_threeTimes_whenAnotherFlowIsActive_doesNotShowSheetAndKeepsCount() {
        let store = MockPreferenceStore()
        let preferences = AppPreferences(store: store)
        let coordinator = AppFlowCoordinator(
            store: StoreManager(defaults: MockPreferenceStore()),
            preferences: preferences,
            scheduler: ImmediateScheduler()
        )
        coordinator.activeFlow = .trick(trick: trick)

        coordinator.recordTrickClose()
        coordinator.recordTrickClose()
        coordinator.recordTrickClose()

        XCTAssertNotEqual(coordinator.activeSheet, .rateApp)
        XCTAssertEqual(preferences.trickLaunchCount, 3)
    }

    func test_openStartFlow_forUnseenTrick_showsInstructionFirstLaunch() {
        let coordinator = AppFlowCoordinator(
            store: StoreManager(defaults: MockPreferenceStore()),
            preferences: AppPreferences(store: MockPreferenceStore())
        )

        coordinator.openStartFlow(for: trick)

        XCTAssertEqual(
            coordinator.activeSheet,
            .instructionFirstLaunch(instruction: trick.instruction, trick: trick)
        )
    }

    func test_openStartFlow_forSeenTrick_opensTrickDirectly() {
        let coordinator = AppFlowCoordinator(
            store: StoreManager(defaults: MockPreferenceStore()),
            preferences: AppPreferences(store: MockPreferenceStore())
        )
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
    func integer(forKey defaultName: String) -> Int { (storage[defaultName] as? Int) ?? 0 }
    func stringArray(forKey defaultName: String) -> [String]? { storage[defaultName] as? [String] }
    func set(_ value: Any?, forKey defaultName: String) { storage[defaultName] = value }
}
