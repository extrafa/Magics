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

    func test_toggled_ticksAndUnticksASingleGoal() {
        let ticked = Set<OnboardingGoal>().toggled(.dates)
        XCTAssertEqual(ticked, [.dates])

        XCTAssertEqual(ticked.toggled(.dates), [])
    }

    func test_toggled_tickingAllFourOthers_becomesEverywhere() {
        var goals = Set<OnboardingGoal>()
        for goal in OnboardingGoal.combinable { goals = goals.toggled(goal) }

        XCTAssertEqual(goals, Set(OnboardingGoal.allCases))
    }

    func test_toggled_everywhere_ticksAllAndUnticksAll() {
        let all = Set<OnboardingGoal>().toggled(.everywhere)
        XCTAssertEqual(all, Set(OnboardingGoal.allCases))

        XCTAssertEqual(all.toggled(.everywhere), [])
    }

    func test_toggled_aMutedGoalWhileEverywhereIsOn_selectsJustThatGoal() {
        let everywhere = Set(OnboardingGoal.allCases)

        XCTAssertEqual(everywhere.toggled(.parties), [.parties])
    }

    func test_complete_calledTwice_finishesOnlyOnce() {
        var completions = 0
        let viewModel = OnboardingViewModel(preferences: MockOnboardingPreferences(), onComplete: { completions += 1 })

        viewModel.complete()
        viewModel.complete()

        XCTAssertEqual(completions, 1)
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
