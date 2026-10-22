//
//  ColorSenseViewModelTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class ColorSenseViewModelTests: XCTestCase {

    func test_everyColor_hasItsOwnVibrationCount() {
        XCTAssertEqual(ColorCardType.red.vibrations, 1)
        XCTAssertEqual(ColorCardType.green.vibrations, 2)
        XCTAssertEqual(ColorCardType.blue.vibrations, 3)
        XCTAssertEqual(ColorCardType.yellow.vibrations, 4)
    }

    func test_tap_marksTheCardActive_thenClearsItAfterTheTapAnimation() async throws {
        let viewModel = ColorSenseViewModel(haptics: MockCountHaptics())
        let card = try XCTUnwrap(viewModel.cards.first)

        viewModel.handleTap(on: card)

        XCTAssertEqual(viewModel.activeTapCardID, card.id)
        XCTAssertFalse(viewModel.canTap)
        await waitUntil { viewModel.activeTapCardID == nil }
    }

    func test_tap_playsTheCountOfTheCardColor_andAllowsTapsAgainWhenTheSignalEnds() async throws {
        let haptics = MockCountHaptics()
        let viewModel = ColorSenseViewModel(haptics: haptics)
        let blue = try XCTUnwrap(viewModel.cards.first { $0.colorType == .blue })

        viewModel.handleTap(on: blue)
        await waitUntil { !haptics.playedCounts.isEmpty }

        XCTAssertEqual(haptics.playedCounts, [3])
        XCTAssertFalse(viewModel.canTap)

        haptics.finishPlaying()

        XCTAssertTrue(viewModel.canTap)
    }

    func test_tapWhileASignalIsPending_isIgnored() async throws {
        let haptics = MockCountHaptics()
        let viewModel = ColorSenseViewModel(haptics: haptics)
        let first = viewModel.cards[0]
        let second = viewModel.cards[1]

        viewModel.handleTap(on: first)
        viewModel.handleTap(on: second)

        XCTAssertEqual(viewModel.activeTapCardID, first.id)
        await waitUntil { !haptics.playedCounts.isEmpty }
        XCTAssertEqual(haptics.playedCounts.count, 1)
    }

    func test_cancel_beforeTheSignalStarts_playsNothingAndResetsTheState() async throws {
        let haptics = MockCountHaptics()
        let viewModel = ColorSenseViewModel(haptics: haptics)

        viewModel.handleTap(on: viewModel.cards[0])
        viewModel.cancel()
        try await Task.sleep(nanoseconds: 1_300_000_000)

        XCTAssertTrue(haptics.playedCounts.isEmpty)
        XCTAssertEqual(haptics.cancelCount, 1)
        XCTAssertTrue(viewModel.canTap)
        XCTAssertNil(viewModel.activeTapCardID)
    }

    // Waits for a state change driven by a fire-and-forget Task inside the view model, failing on timeout.
    private func waitUntil(
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Timed out waiting for condition", file: file, line: line)
                return
            }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}
