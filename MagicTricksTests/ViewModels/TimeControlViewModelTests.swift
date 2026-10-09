//
//  TimeControlViewModelTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class TimeControlViewModelTests: XCTestCase {

    func test_formattedTime_beforeAnyRun_isZero() {
        let viewModel = makeViewModel().viewModel

        XCTAssertEqual(viewModel.formattedTime, "00:00.00")
    }

    func test_stop_afterElapsedTime_formatsMinutesSecondsAndHundredths() {
        let (viewModel, clock, _) = makeViewModel()

        viewModel.handlePrimaryAction()
        clock.advance(by: 65.435)
        viewModel.handlePrimaryAction()

        XCTAssertEqual(viewModel.formattedTime, "01:05.43")
        XCTAssertFalse(viewModel.isRunning)
    }

    func test_stop_transmitsSecondsAndHundredthsOfTheStoppedTime() async {
        let (viewModel, clock, transmitter) = makeViewModel()

        viewModel.handlePrimaryAction()
        clock.advance(by: 65.435)
        viewModel.handlePrimaryAction()
        await waitUntil { transmitter.transmitted != nil }

        XCTAssertEqual(transmitter.transmitted?.second, 5)
        XCTAssertEqual(transmitter.transmitted?.hundredths, 43)
    }

    func test_reset_afterStop_clearsTheTimeAndDisablesReset() {
        let (viewModel, clock, _) = makeViewModel()
        viewModel.handlePrimaryAction()
        clock.advance(by: 3.215)
        viewModel.handlePrimaryAction()
        XCTAssertTrue(viewModel.canReset)

        viewModel.reset()

        XCTAssertEqual(viewModel.formattedTime, "00:00.00")
        XCTAssertFalse(viewModel.canReset)
    }

    func test_handleSceneBecameActive_restartsHapticEngine() {
        let engine = MockHapticEngine()
        let viewModel = TimeControlViewModel(signalTransmitter: MockSignalTransmitter(), hapticEngineManager: engine)

        viewModel.handleSceneBecameActive()

        XCTAssertEqual(engine.restartCount, 1)
    }

    // MARK: - Transmission phases

    func test_canUsePrimaryAction_whileSignalIsPlaying_isFalseAndIgnoresTaps() async {
        let (viewModel, transmitter) = await makeViewModelTransmitting()
        let cancelsBefore = transmitter.cancelCount

        transmitter.emit(.playingSeconds)

        XCTAssertFalse(viewModel.canUsePrimaryAction)
        viewModel.handlePrimaryAction()
        XCTAssertFalse(viewModel.isRunning)
        XCTAssertEqual(transmitter.cancelCount, cancelsBefore)
    }

    func test_canUsePrimaryAction_whileWaitingForStartTrigger_isTrue() async {
        let (viewModel, transmitter) = await makeViewModelTransmitting()

        transmitter.emit(.waitingForStartTrigger)

        XCTAssertTrue(viewModel.canUsePrimaryAction)
    }

    func test_primaryAction_whileWaitingForStartTrigger_cancelsTransmissionAndRestartsTimer() async {
        let (viewModel, transmitter) = await makeViewModelTransmitting()
        let cancelsBefore = transmitter.cancelCount
        transmitter.emit(.waitingForStartTrigger)

        viewModel.handlePrimaryAction()

        XCTAssertEqual(transmitter.cancelCount, cancelsBefore + 1)
        XCTAssertFalse(viewModel.isTransmitting)
        XCTAssertTrue(viewModel.isRunning)
    }

    func test_transmissionFinishing_clearsTransmittingState() async {
        let (viewModel, transmitter) = await makeViewModelTransmitting()
        transmitter.emit(.playingHundredths)

        transmitter.finish()
        await waitUntil { !viewModel.isTransmitting }

        XCTAssertTrue(viewModel.canUsePrimaryAction)
    }

    func test_onDisappear_duringTransmission_cancelsItAndStopsRunning() async {
        let (viewModel, transmitter) = await makeViewModelTransmitting()
        let cancelsBefore = transmitter.cancelCount
        transmitter.emit(.playingSeconds)

        viewModel.onDisappear()

        XCTAssertEqual(transmitter.cancelCount, cancelsBefore + 1)
        XCTAssertFalse(viewModel.isTransmitting)
        XCTAssertFalse(viewModel.isRunning)
    }

    // MARK: - Helpers

    private func makeViewModel() -> (viewModel: TimeControlViewModel, clock: FakeClock, transmitter: MockSignalTransmitter) {
        let clock = FakeClock()
        let transmitter = MockSignalTransmitter()
        let viewModel = TimeControlViewModel(
            signalTransmitter: transmitter,
            hapticEngineManager: MockHapticEngine(),
            now: { clock.now }
        )
        return (viewModel, clock, transmitter)
    }

    // Runs the timer, stops it, and returns once the (suspended) transmission has actually begun.
    // transmit() cancels any previous transmission first, so cancelCount is already 1 here; assert on deltas.
    private func makeViewModelTransmitting() async -> (TimeControlViewModel, ControllableTransmitter) {
        let clock = FakeClock()
        let transmitter = ControllableTransmitter()
        let viewModel = TimeControlViewModel(
            signalTransmitter: transmitter,
            hapticEngineManager: MockHapticEngine(),
            now: { clock.now }
        )
        viewModel.handlePrimaryAction()
        clock.advance(by: 12.345)
        viewModel.handlePrimaryAction()
        await waitUntil { viewModel.isTransmitting && transmitter.isTransmitting }
        return (viewModel, transmitter)
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

private final class FakeClock {
    private(set) var now = Date(timeIntervalSince1970: 1_000)

    func advance(by interval: TimeInterval) {
        now = now.addingTimeInterval(interval)
    }
}

@MainActor
private final class MockSignalTransmitter: TimeControlSignalTransmitting {
    var transmitted: (second: Int, hundredths: Int)?

    func transmit(
        second: Int,
        hundredths: Int,
        onPhaseChange: @escaping (TimeControlTransmissionPhase) -> Void
    ) async {
        transmitted = (second, hundredths)
    }

    func cancel() {}
}

@MainActor
private final class MockHapticEngine: HapticEngineManaging {
    var restartCount = 0

    func restartEngineIfNeeded() {
        restartCount += 1
    }
}

@MainActor
private final class ControllableTransmitter: TimeControlSignalTransmitting {
    private(set) var cancelCount = 0
    private var onPhaseChange: ((TimeControlTransmissionPhase) -> Void)?
    private var continuation: CheckedContinuation<Void, Never>?

    var isTransmitting: Bool { continuation != nil }

    func transmit(
        second: Int,
        hundredths: Int,
        onPhaseChange: @escaping (TimeControlTransmissionPhase) -> Void
    ) async {
        self.onPhaseChange = onPhaseChange
        await withCheckedContinuation { continuation = $0 }
    }

    func emit(_ phase: TimeControlTransmissionPhase) {
        onPhaseChange?(phase)
    }

    func finish() {
        continuation?.resume()
        continuation = nil
    }

    func cancel() {
        cancelCount += 1
        finish()
    }
}
