//
//  PhantomDrawViewModelTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class PhantomDrawViewModelTests: XCTestCase {

    func test_onNewConnection_asSender_resendsCanvasAspectRatioAlongsideSync() {
        let session = MockPhantomDrawSession()
        let vm = PhantomDrawViewModel(session: session)
        vm.role = .sender
        vm.setCanvasSize(CGSize(width: 390, height: 844))
        session.sentMessages = []

        session.onNewConnection?()

        XCTAssertTrue(session.sentMessages.contains(.sync([])))
        XCTAssertTrue(session.sentMessages.contains(.canvasAspectRatio(390.0 / 844.0)))
    }

    func test_onNewConnection_beforeCanvasSizeIsKnown_sendsOnlySync() {
        let session = MockPhantomDrawSession()
        let vm = PhantomDrawViewModel(session: session)
        vm.role = .sender

        session.onNewConnection?()

        XCTAssertEqual(session.sentMessages, [.sync([])])
    }

    func test_onNewConnection_asReceiver_sendsNothing() {
        let session = MockPhantomDrawSession()
        let vm = PhantomDrawViewModel(session: session)
        vm.role = .receiver
        vm.setCanvasSize(CGSize(width: 390, height: 844))
        session.sentMessages = []

        session.onNewConnection?()

        XCTAssertTrue(session.sentMessages.isEmpty)
    }

    // MARK: - Trash exit

    func test_trashTapped_fourQuickTaps_closeTheTrickOnTheFourth() {
        let clock = FakeClock()
        let vm = PhantomDrawViewModel(session: MockPhantomDrawSession(), clock: clock.read)

        let results = (0..<4).map { _ -> Bool in
            clock.advance(by: 0.3)
            return vm.trashTapped()
        }

        XCTAssertEqual(results, [false, false, false, true])
    }

    func test_trashTapped_threeTaps_doNotClose() {
        let clock = FakeClock()
        let vm = PhantomDrawViewModel(session: MockPhantomDrawSession(), clock: clock.read)

        let results = (0..<3).map { _ -> Bool in
            clock.advance(by: 0.3)
            return vm.trashTapped()
        }

        XCTAssertEqual(results, [false, false, false])
    }

    func test_trashTapped_aPauseLongerThanTheWindow_startsTheCountAgain() {
        let clock = FakeClock()
        let vm = PhantomDrawViewModel(session: MockPhantomDrawSession(), clock: clock.read)
        _ = vm.trashTapped()
        clock.advance(by: 0.3)
        _ = vm.trashTapped()
        clock.advance(by: 0.3)
        _ = vm.trashTapped()

        clock.advance(by: 1.5)
        let afterPause = vm.trashTapped()
        clock.advance(by: 0.3)
        _ = vm.trashTapped()
        clock.advance(by: 0.3)
        let third = vm.trashTapped()

        XCTAssertFalse(afterPause)
        XCTAssertFalse(third, "only three taps since the pause")
    }

    func test_trashTapped_afterClosing_countsFromZeroAgain() {
        let clock = FakeClock()
        let vm = PhantomDrawViewModel(session: MockPhantomDrawSession(), clock: clock.read)
        for _ in 0..<4 {
            clock.advance(by: 0.3)
            _ = vm.trashTapped()
        }

        clock.advance(by: 0.3)

        XCTAssertFalse(vm.trashTapped())
    }

    func test_trashTapped_clearsTheCanvasOnEveryTap() {
        let session = MockPhantomDrawSession()
        let clock = FakeClock()
        let vm = PhantomDrawViewModel(session: session, clock: clock.read)

        _ = vm.trashTapped()
        clock.advance(by: 0.3)
        _ = vm.trashTapped()

        XCTAssertEqual(session.sentMessages, [.clear, .clear])
    }
}

private final class FakeClock {
    private var now = Date(timeIntervalSince1970: 1_000)

    func advance(by interval: TimeInterval) {
        now = now.addingTimeInterval(interval)
    }

    func read() -> Date { now }
}

@MainActor
private final class MockPhantomDrawSession: PhantomDrawSessioning {
    var connectionState: PhantomDrawConnectionState = .idle
    var onNewConnection: Completion?
    var sentMessages: [PhantomDrawMessage] = []

    func startAsReceiver(code: String) {}
    func startAsSender() {}
    func send(_ message: PhantomDrawMessage) { sentMessages.append(message) }
    func stop() {}
}
