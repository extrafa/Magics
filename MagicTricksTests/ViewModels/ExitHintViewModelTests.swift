//
//  ExitHintViewModelTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class ExitHintViewModelTests: XCTestCase {

    private let schedule = ExitHintFadeSchedule(initialDelay: 0.05, dimDuration: 0.05, hideDuration: 0.05)

    func test_autoFade_dimsThenHidesThenCompletes() async {
        let (viewModel, completions) = makeViewModel()

        viewModel.configurePresentation(isVisible: true, onAutoFadeComplete: { completions.increment() })
        await waitUntil { completions.count == 1 }

        XCTAssertEqual(viewModel.hintOpacity, ExitHintOpacity.hidden)
    }

    func test_holdingTheZone_pausesTheFade() async {
        let (viewModel, completions) = makeViewModel()
        viewModel.configurePresentation(isVisible: true, onAutoFadeComplete: { completions.increment() })

        viewModel.holdStarted()
        try? await Task.sleep(milliseconds: 300)

        XCTAssertEqual(completions.count, 0)
        XCTAssertEqual(viewModel.hintOpacity, ExitHintOpacity.visible)
    }

    func test_releasingTheZoneBeforeTheHintDims_letsTheFadeFinish() async {
        let (viewModel, completions) = makeViewModel()
        viewModel.configurePresentation(isVisible: true, onAutoFadeComplete: { completions.increment() })
        viewModel.holdStarted()

        viewModel.holdCancelled()
        await waitUntil { completions.count == 1 }

        XCTAssertEqual(viewModel.hintOpacity, ExitHintOpacity.hidden)
    }

    func test_releasingTheZoneWhileDimmed_continuesFromThere() async {
        let (viewModel, completions) = makeViewModel()
        viewModel.configurePresentation(isVisible: true, onAutoFadeComplete: { completions.increment() })
        await waitUntil { viewModel.hintOpacity == ExitHintOpacity.dimmed }
        viewModel.holdStarted()
        try? await Task.sleep(milliseconds: 300)
        XCTAssertEqual(completions.count, 0)
        XCTAssertEqual(viewModel.hintOpacity, ExitHintOpacity.dimmed)

        viewModel.holdCancelled()
        await waitUntil { completions.count == 1 }

        XCTAssertEqual(viewModel.hintOpacity, ExitHintOpacity.hidden)
    }

    func test_releasingTheZoneAfterTheFadeFinished_doesNotCompleteAgain() async {
        let (viewModel, completions) = makeViewModel()
        viewModel.configurePresentation(isVisible: true, onAutoFadeComplete: { completions.increment() })
        await waitUntil { completions.count == 1 }

        viewModel.holdStarted()
        viewModel.holdCancelled()
        try? await Task.sleep(milliseconds: 300)

        XCTAssertEqual(completions.count, 1)
    }

    func test_releasingTheZoneAfterTheHintWasTurnedOff_doesNotRestartTheFade() async {
        let (viewModel, completions) = makeViewModel()
        viewModel.configurePresentation(isVisible: true, onAutoFadeComplete: { completions.increment() })
        viewModel.holdStarted()
        viewModel.cancelAutoFade()

        viewModel.holdCancelled()
        try? await Task.sleep(milliseconds: 300)

        XCTAssertEqual(completions.count, 0)
    }

    func test_beforeTheHintIsLearned_theFadeNeverStarts() async {
        let (viewModel, completions) = makeViewModel(didLearn: false)

        viewModel.configurePresentation(isVisible: true, onAutoFadeComplete: { completions.increment() })
        viewModel.holdStarted()
        viewModel.holdCancelled()
        try? await Task.sleep(milliseconds: 300)

        XCTAssertEqual(completions.count, 0)
        XCTAssertEqual(viewModel.hintOpacity, ExitHintOpacity.visible)
    }

    private func makeViewModel(didLearn: Bool = true) -> (ExitHintViewModel, CompletionCounter) {
        let viewModel = ExitHintViewModel(
            preferences: MockExitHintPreferences(didLearnExitHint: didLearn),
            fadeSchedule: schedule
        )
        return (viewModel, CompletionCounter())
    }

    // Waits for a state change driven by a Task inside the view model, failing on timeout.
    private func waitUntil(
        timeout: TimeInterval = 2,
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
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }
}

private final class CompletionCounter {
    private(set) var count = 0

    func increment() {
        count += 1
    }
}

private struct MockExitHintPreferences: ExitHintPreferenceManaging {
    var didLearnExitHint: Bool
    var isExitHintEnabled = true
}
