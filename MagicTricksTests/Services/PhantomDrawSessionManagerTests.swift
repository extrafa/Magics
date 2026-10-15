//
//  PhantomDrawSessionManagerTests.swift
//  MagicTricksTests
//

import Network
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

    func test_isLocalNetworkDenied_forPolicyDeniedDNSError_isTrue() {
        let error = NWError.dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied))

        XCTAssertTrue(PhantomDrawSessionManager.isLocalNetworkDenied(error))
    }

    func test_isLocalNetworkDenied_forOtherErrors_isFalse() {
        XCTAssertFalse(PhantomDrawSessionManager.isLocalNetworkDenied(.dns(DNSServiceErrorType(kDNSServiceErr_NoSuchRecord))))
        XCTAssertFalse(PhantomDrawSessionManager.isLocalNetworkDenied(.posix(.ECONNREFUSED)))
    }

    func test_browserWaitingWithPolicyDenied_doesNotShowTheDeniedStateRightAway() {
        let manager = PhantomDrawSessionManager(scheduler: FakeScheduler())
        addTeardownBlock { manager.stop() }

        manager.startAsReceiver(code: "42")
        manager.handleBrowserState(.waiting(.dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied))))

        XCTAssertEqual(manager.connectionState, .searching)
    }

    func test_browserWaitingWithPolicyDenied_entersLocalNetworkDeniedAfterTheDelay_andSearchTimeoutKeepsIt() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }

        manager.startAsReceiver(code: "42")
        manager.handleBrowserState(.waiting(.dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied))))
        scheduler.fire(at: 1)
        XCTAssertEqual(manager.connectionState, .localNetworkDenied)

        scheduler.fire(at: 0)
        XCTAssertEqual(manager.connectionState, .localNetworkDenied)
    }

    func test_browserReadyBeforeTheDelay_cancelsThePendingDeniedState() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }

        manager.startAsReceiver(code: "42")
        manager.handleBrowserState(.waiting(.dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied))))
        manager.handleBrowserState(.ready)
        scheduler.fire(at: 1)

        XCTAssertEqual(manager.connectionState, .searching)
    }

    func test_repeatedDeniedEvents_scheduleOneConfirmation() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }
        manager.startAsReceiver(code: "42")
        let scheduledBefore = scheduler.pendingCount

        for _ in 0..<3 {
            manager.handleBrowserState(.waiting(.dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied))))
        }

        XCTAssertEqual(scheduler.pendingCount, scheduledBefore + 1)
    }

    func test_prepareForCodeEntry_afterDenial_stopsTheSearchAndWaitsForACode() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }
        manager.startAsReceiver(code: "42")
        manager.handleBrowserState(.waiting(.dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied))))
        scheduler.fire(at: 1)

        manager.prepareForCodeEntry()
        manager.handleBrowserState(.ready)
        scheduler.fire(at: 0)

        XCTAssertEqual(manager.connectionState, .enteringCode)
    }

    func test_startAsReceiver_afterDenial_searchesAgainWithTheNewAttempt() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }
        manager.startAsReceiver(code: "42")
        manager.handleBrowserState(.waiting(.dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied))))
        scheduler.fire(at: 1)

        manager.startAsReceiver(code: "42")

        XCTAssertEqual(manager.connectionState, .searching)
    }

    func test_browserWaitingWithOtherError_doesNotEnterLocalNetworkDenied() {
        let manager = PhantomDrawSessionManager(scheduler: FakeScheduler())
        addTeardownBlock { manager.stop() }

        manager.startAsReceiver(code: "42")
        manager.handleBrowserState(.waiting(.posix(.ENETDOWN)))

        XCTAssertEqual(manager.connectionState, .searching)
    }

    func test_browserReady_afterDenied_resumesSearchingWithAFreshTimeout() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }

        manager.startAsReceiver(code: "42")
        manager.handleBrowserState(.waiting(.dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied))))
        scheduler.fire(at: 1)
        XCTAssertEqual(manager.connectionState, .localNetworkDenied)
        manager.handleBrowserState(.ready)

        XCTAssertEqual(manager.connectionState, .searching)

        scheduler.fire(at: 1)
        XCTAssertEqual(manager.connectionState, .failed)
    }

    func test_browserReady_whileSearching_changesNothing() {
        let manager = PhantomDrawSessionManager(scheduler: FakeScheduler())
        addTeardownBlock { manager.stop() }

        manager.startAsReceiver(code: "42")
        manager.handleBrowserState(.ready)

        XCTAssertEqual(manager.connectionState, .searching)
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

    var pendingCount: Int { scheduledActions.count }

    // Fires the oldest pending action by default; pass the index to fire a later one.
    func fire(at index: Int = 0) {
        guard scheduledActions.indices.contains(index) else { return }
        scheduledActions.remove(at: index)()
    }
}
