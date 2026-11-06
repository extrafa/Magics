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

    func test_selectRole_asReceiver_stopsAnySearchAndWaitsForACode() {
        let session = MockPhantomDrawSession()
        let vm = PhantomDrawViewModel(session: session)

        vm.selectRole(.receiver)

        XCTAssertEqual(session.preparedForCodeEntryCount, 1)
        XCTAssertEqual(session.connectionState, .enteringCode)
        XCTAssertEqual(vm.role, .receiver)
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

    // MARK: - Limits the receiver enforces

    func test_aVeryLongLine_isSplitIntoStrokesTheReceiverKeeps() {
        let session = MockPhantomDrawSession()
        let vm = PhantomDrawViewModel(session: session)
        vm.role = .sender
        let maxPoints = PhantomDrawSessionManager.maxPointsPerStroke

        for i in 0..<(maxPoints * 2 + 10) {
            vm.addPoint(CGPoint(x: CGFloat(i) * 3, y: 0))
        }
        vm.commitStroke()

        XCTAssertEqual(vm.completedStrokes.count, 3)
        XCTAssertTrue(vm.completedStrokes.allSatisfy { $0.points.count <= maxPoints })
        // The line goes on without a gap: each stroke starts where the one before it ended.
        for (previous, next) in zip(vm.completedStrokes, vm.completedStrokes.dropFirst()) {
            XCTAssertEqual(previous.points.last, next.points.first)
        }
    }

    func test_moreStrokesThanTheReceiverKeeps_dropTheOldestOnes() {
        let session = MockPhantomDrawSession()
        let vm = PhantomDrawViewModel(session: session)
        vm.role = .sender
        let limit = PhantomDrawSessionManager.maxStrokes

        for _ in 0..<(limit + 5) {
            vm.addPoint(.zero)
            vm.commitStroke()
        }

        XCTAssertEqual(vm.completedStrokes.count, limit)
        let sentStrokes = session.sentMessages.compactMap { message -> DrawingStroke? in
            if case .stroke(let stroke) = message { return stroke }
            return nil
        }
        XCTAssertEqual(vm.completedStrokes.first, sentStrokes[5])
        XCTAssertEqual(vm.completedStrokes.last, sentStrokes.last)
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
    private(set) var preparedForCodeEntryCount = 0

    func startAsReceiver(code: String) {}
    func prepareForCodeEntry() {
        preparedForCodeEntryCount += 1
        connectionState = .enteringCode
    }
    func startAsSender() {}
    func send(_ message: PhantomDrawMessage) { sentMessages.append(message) }
    func stop() {}
}
