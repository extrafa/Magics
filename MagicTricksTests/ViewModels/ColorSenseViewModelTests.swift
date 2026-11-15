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

    // What the grid takes on the screen for the cards in this order: each row is as tall as its tallest card.
    private func naturalHeight(of cards: [ColorCard]) -> CGFloat {
        let rows = stride(from: 0, to: cards.count, by: 2).map { max(cards[$0].height, cards[$0 + 1].height) }
        return rows.reduce(0, +) + CGFloat(rows.count - 1) * ColorSenseViewModel.gridSpacing
    }

    func test_gridHeight_isTheMostTheGridCanTake_inAnyOrderOfTheCards() {
        let viewModel = ColorSenseViewModel(haptics: MockCountHaptics())
        let tallestFour = viewModel.cards.map(\.height).sorted(by: >).prefix(4).reduce(0, +)
        var tallestSeen: CGFloat = 0

        for _ in 0..<300 {
            viewModel.shuffleCards()
            let height = naturalHeight(of: viewModel.cards)
            XCTAssertLessThanOrEqual(height, viewModel.gridHeight + 0.001)
            tallestSeen = max(tallestSeen, height)
        }

        XCTAssertEqual(viewModel.gridHeight, tallestFour + 3 * ColorSenseViewModel.gridSpacing)
        XCTAssertEqual(tallestSeen, viewModel.gridHeight, accuracy: 0.001)
    }

    func test_shuffling_doesNotChangeTheScaleOfTheCards() {
        let viewModel = ColorSenseViewModel(haptics: MockCountHaptics())
        let before = viewModel.heightScale(forAvailableHeight: 600)

        viewModel.shuffleCards()

        XCTAssertEqual(viewModel.heightScale(forAvailableHeight: 600), before)
    }

    func test_shuffleCards_keepsEveryCard_andChangesTheirOrder() {
        let viewModel = ColorSenseViewModel(haptics: MockCountHaptics())
        let before = viewModel.cards.map(\.id)
        var ordersSeen = Set<[UUID]>()

        for _ in 0..<20 {
            viewModel.shuffleCards()
            XCTAssertEqual(Set(viewModel.cards.map(\.id)), Set(before))
            ordersSeen.insert(viewModel.cards.map(\.id))
        }

        XCTAssertGreaterThan(ordersSeen.count, 1)
    }

    func test_heightScale_onATallScreen_keepsTheCardsAsTheyAre() {
        let viewModel = ColorSenseViewModel(haptics: MockCountHaptics())

        XCTAssertEqual(viewModel.heightScale(forAvailableHeight: viewModel.gridHeight + 200), 1)
    }

    func test_heightScale_onAShortScreen_makesTheGridFitExactly() {
        let viewModel = ColorSenseViewModel(haptics: MockCountHaptics())
        let available = viewModel.gridHeight - 150

        let scale = viewModel.heightScale(forAvailableHeight: available)

        XCTAssertLessThan(scale, 1)
        XCTAssertEqual(viewModel.gridHeight * scale, available, accuracy: 0.001)
    }

    func test_heightScale_withNoMeasuredHeight_changesNothing() {
        let viewModel = ColorSenseViewModel(haptics: MockCountHaptics())

        XCTAssertEqual(viewModel.heightScale(forAvailableHeight: 0), 1)
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

@MainActor
final class ShuffleFlightTests: XCTestCase {

    func test_theFirstShuffleRuns_andOneThatFollowsAtOnceDoesNot() {
        var time = Date(timeIntervalSince1970: 1_000)
        let flight = ShuffleFlight<Int>(now: { time })
        var reorders = 0

        XCTAssertTrue(flight.run(reduceMotion: true, reorder: { reorders += 1 }, ids: { [1, 2, 3] }))
        time = time.addingTimeInterval(0.3)
        XCTAssertFalse(flight.run(reduceMotion: true, reorder: { reorders += 1 }, ids: { [1, 2, 3] }))

        XCTAssertEqual(reorders, 1)
    }

    func test_aShuffleRunsAgain_onceTheLastOneHasSettled() {
        var time = Date(timeIntervalSince1970: 1_000)
        let flight = ShuffleFlight<Int>(now: { time })
        var reorders = 0

        flight.run(reduceMotion: true, reorder: { reorders += 1 }, ids: { [1] })
        time = time.addingTimeInterval(ShuffleFlight<Int>.cooldown + 0.01)
        XCTAssertTrue(flight.run(reduceMotion: true, reorder: { reorders += 1 }, ids: { [1] }))

        XCTAssertEqual(reorders, 2)
    }

    func test_withReducedMotion_noItemIsTipped() {
        let flight = ShuffleFlight<Int>()

        flight.run(reduceMotion: true, reorder: {}, ids: { [1, 2, 3] })

        XCTAssertTrue(flight.tilt.isEmpty)
    }

    func test_withMotion_everyItemIsTippedByALittle_thenLandsStraight() async {
        let flight = ShuffleFlight<Int>()

        flight.run(reduceMotion: false, reorder: {}, ids: { [1, 2, 3] })

        XCTAssertEqual(Set(flight.tilt.keys), [1, 2, 3])
        XCTAssertTrue(flight.tilt.values.allSatisfy { abs($0) <= 9 })
        for _ in 0..<100 where !flight.tilt.isEmpty {
            try? await Task.sleep(milliseconds: 20)
        }
        XCTAssertTrue(flight.tilt.isEmpty)
    }
}

