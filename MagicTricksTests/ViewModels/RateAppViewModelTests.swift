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

    func test_like_setsHasRespondedToRating() {
        let preferences = MockRateAppPreferences()
        let viewModel = RateAppViewModel(preferences: preferences)

        viewModel.like()

        XCTAssertTrue(preferences.hasRespondedToRating)
    }

    func test_dislike_switchesPhaseWithoutRecordingAResponse() {
        let preferences = MockRateAppPreferences()
        let viewModel = RateAppViewModel(preferences: preferences)

        viewModel.dislike()

        XCTAssertEqual(viewModel.phase, .disliked)
        XCTAssertFalse(preferences.hasRespondedToRating)
        XCTAssertNil(preferences.ratingSnoozedUntil)
    }

    func test_writeToUs_setsHasRespondedToRatingAndReturnsMailURL() {
        let preferences = MockRateAppPreferences()
        let viewModel = RateAppViewModel(preferences: preferences)

        let url = viewModel.writeToUs()

        XCTAssertTrue(preferences.hasRespondedToRating)
        XCTAssertEqual(url?.scheme, "mailto")
        XCTAssertEqual(url?.absoluteString.contains(AppConfig.supportEmail), true)
    }

    func test_markDismissed_snoozesIntoTheFuture() throws {
        let preferences = MockRateAppPreferences()
        let viewModel = RateAppViewModel(preferences: preferences)

        viewModel.markDismissed()

        let snoozedUntil = try XCTUnwrap(preferences.ratingSnoozedUntil)
        XCTAssertGreaterThan(snoozedUntil, Date())
    }
}

private struct MockRateAppPreferences: RateAppPreferenceManaging {
    var hasRespondedToRating = false
    var ratingSnoozedUntil: Date?
}
