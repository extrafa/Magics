//
//  RateAppViewModelTests.swift
//  MagicTricksTests
//
//  Created by Ross on 01/09/2026.
//

import XCTest
@testable import MagicTricks

@MainActor
final class RateAppViewModelTests: XCTestCase {

    func test_recordReviewShown_setsHasRespondedToRating() {
        let preferences = MockRateAppPreferences()
        let viewModel = RateAppViewModel(preferences: preferences)

        viewModel.recordReviewShown()

        XCTAssertTrue(preferences.hasRespondedToRating)
    }

    func test_dislike_switchesPhaseWithoutRecordingAResponse() {
        let preferences = MockRateAppPreferences()
        let viewModel = RateAppViewModel(preferences: preferences)

        viewModel.dislike()

        XCTAssertEqual(viewModel.phase, .disliked)
        XCTAssertFalse(preferences.hasRespondedToRating)
    }

    func test_writeToUs_setsHasRespondedToRatingAndReturnsMailURL() {
        let preferences = MockRateAppPreferences()
        let viewModel = RateAppViewModel(preferences: preferences)

        let url = viewModel.writeToUs()

        XCTAssertTrue(preferences.hasRespondedToRating)
        XCTAssertEqual(url?.scheme, "mailto")
        XCTAssertEqual(url?.absoluteString.contains(AppConfig.supportEmail), true)
    }

    func test_markDismissed_marksTheSheetAsAnswered() {
        let preferences = MockRateAppPreferences()
        let viewModel = RateAppViewModel(preferences: preferences)

        viewModel.markDismissed()

        XCTAssertTrue(preferences.hasRespondedToRating)
    }
}

// A class, not a struct: RateAppViewModel stores its own copy of the
// preferences value, so a struct mock's mutations wouldn't be visible here.
private final class MockRateAppPreferences: RateAppPreferenceManaging {
    var hasRespondedToRating = false
    var trickLaunchCount = 0
}
