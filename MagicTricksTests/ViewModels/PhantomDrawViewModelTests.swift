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
