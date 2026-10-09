//
//  PhantomDrawSessionManagerTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class PhantomDrawSessionManagerTests: XCTestCase {

    private let manager = PhantomDrawSessionManager()

    func test_activeConnectionLost_entersReconnectingWithoutChangingConnectionState() {
        let manager = PhantomDrawSessionManager(scheduler: FakeScheduler())
        manager.connectionState = .connected(peerName: "Spectator's iPhone")

        manager.handleActiveConnectionLost()

        XCTAssertTrue(manager.isReconnecting)
        XCTAssertEqual(manager.connectionState, .connected(peerName: "Spectator's iPhone"))
    }

    func test_reconnectTimeout_whenStillReconnecting_fallsBackToFailed() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .connected(peerName: "Spectator's iPhone")

        manager.handleActiveConnectionLost()
        scheduler.fire()

        XCTAssertFalse(manager.isReconnecting)
        XCTAssertEqual(manager.connectionState, .failed)
    }

    func test_reconnectTimeout_whenAlreadyReconnected_doesNothing() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .connected(peerName: "Spectator's iPhone")

        manager.handleActiveConnectionLost()
        // Simulates a successful reconnect landing before the stale timeout fires.
        manager.isReconnecting = false
        manager.connectionState = .connected(peerName: "New iPhone")
        scheduler.fire()

        XCTAssertEqual(manager.connectionState, .connected(peerName: "New iPhone"))
    }

    func test_searchTimeout_whenReceiverNeverConnects_fallsBackToFailed() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }

        manager.startAsReceiver(code: "42")
        XCTAssertEqual(manager.connectionState, .searching)
        scheduler.fire()

        XCTAssertEqual(manager.connectionState, .failed)
    }

    func test_searchTimeout_whenReceiverConnectedMeanwhile_doesNothing() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }

        manager.startAsReceiver(code: "42")
        manager.connectionState = .connected(peerName: "Sender")
        scheduler.fire()

        XCTAssertEqual(manager.connectionState, .connected(peerName: "Sender"))
    }

    func test_searchTimeout_fromEarlierSearchDoesNotFailARetry() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }

        manager.startAsReceiver(code: "42")
        manager.startAsReceiver(code: "42")
        scheduler.fire(at: 0)

        XCTAssertEqual(manager.connectionState, .searching)

        scheduler.fire()
        XCTAssertEqual(manager.connectionState, .failed)
    }

    func test_reconnectTimeout_fromEarlierDropDoesNotFailALaterReconnect() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .connected(peerName: "Spectator's iPhone")

        manager.handleActiveConnectionLost()
        manager.isReconnecting = false
        manager.handleActiveConnectionLost()
        scheduler.fire(at: 0)

        XCTAssertTrue(manager.isReconnecting)
        XCTAssertEqual(manager.connectionState, .connected(peerName: "Spectator's iPhone"))

        scheduler.fire()
        XCTAssertEqual(manager.connectionState, .failed)
    }

    func test_sanitized_withInRangeStroke_returnsItUnchanged() {
        let stroke = DrawingStroke(id: UUID(), points: [DrawingPoint(x: 0.2, y: 0.8)])

        XCTAssertEqual(manager.sanitized(stroke), stroke)
    }

    func test_sanitized_withOutOfBoundsCoordinates_clampsToUnitRange() throws {
        let stroke = DrawingStroke(
            id: UUID(),
            points: [DrawingPoint(x: -5, y: 1e300), DrawingPoint(x: 0.5, y: -0.001)]
        )

        let sanitized = try XCTUnwrap(manager.sanitized(stroke))

        XCTAssertEqual(sanitized.points[0].x, 0)
        XCTAssertEqual(sanitized.points[0].y, 1)
        XCTAssertEqual(sanitized.points[1].x, 0.5)
        XCTAssertEqual(sanitized.points[1].y, 0)
    }

    func test_sanitized_withEmptyPoints_returnsNil() {
        let stroke = DrawingStroke(id: UUID(), points: [])

        XCTAssertNil(manager.sanitized(stroke))
    }

    func test_sanitized_withTooManyPoints_returnsNil() {
        let stroke = DrawingStroke(
            id: UUID(),
            points: (0...PhantomDrawSessionManager.maxPointsPerStroke).map { _ in DrawingPoint(x: 0, y: 0) }
        )

        XCTAssertNil(manager.sanitized(stroke))
    }

    func test_sanitized_withMaxAllowedPoints_returnsIt() {
        let stroke = DrawingStroke(
            id: UUID(),
            points: (0..<PhantomDrawSessionManager.maxPointsPerStroke).map { _ in DrawingPoint(x: 0, y: 0) }
        )

        XCTAssertNotNil(manager.sanitized(stroke))
    }
}

private final class FakeScheduler: DelayedActionScheduling {
    private var scheduledActions: [Completion] = []

    func schedule(after delay: TimeInterval, action: @escaping Completion) {
        scheduledActions.append(action)
    }

    // Fires the oldest pending action by default; pass the index to fire a later one.
    func fire(at index: Int = 0) {
        guard scheduledActions.indices.contains(index) else { return }
        scheduledActions.remove(at: index)()
    }
}
