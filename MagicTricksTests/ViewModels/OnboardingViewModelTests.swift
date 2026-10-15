//
//  OnboardingViewModelTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    func test_skip_fromAnySkippableStep_jumpsToThePaywall() {
        for step in OnboardingStep.allCases where step.isSkippable {
            let viewModel = OnboardingViewModel(preferences: MockOnboardingPreferences(), onComplete: {})
            viewModel.step = step

            viewModel.skip()

            XCTAssertEqual(viewModel.step, .paywall, "skipping from \(step)")
        }
    }

    func test_skip_doesNotCompleteOnboardingByItself() {
        let preferences = MockOnboardingPreferences()
        var completed = false
        let viewModel = OnboardingViewModel(preferences: preferences, onComplete: { completed = true })

        viewModel.skip()

        XCTAssertFalse(preferences.hasCompletedOnboarding)
        XCTAssertFalse(completed)
    }

    func test_skip_fromTheLoadingScreenOrThePaywall_doesNothing() {
        for step in [OnboardingStep.processing, .paywall] {
            let viewModel = OnboardingViewModel(preferences: MockOnboardingPreferences(), onComplete: {})
            viewModel.step = step

            viewModel.skip()

            XCTAssertEqual(viewModel.step, step)
        }
    }

    func test_isSkippable_isFalseOnlyForTheLoadingScreenAndThePaywall() {
        XCTAssertEqual(
            OnboardingStep.allCases.filter { !$0.isSkippable },
            [.processing, .paywall]
        )
    }

    func test_complete_marksOnboardingAsCompleted() {
        let preferences = MockOnboardingPreferences()
        var completed = false
        let viewModel = OnboardingViewModel(preferences: preferences, onComplete: { completed = true })

        viewModel.complete()

        XCTAssertTrue(preferences.hasCompletedOnboarding)
        XCTAssertTrue(completed)
    }
}

private final class MockOnboardingPreferences: OnboardingPreferenceManaging {
    var hasCompletedOnboarding = false
    var seenTrickIds: [String] = []
}
