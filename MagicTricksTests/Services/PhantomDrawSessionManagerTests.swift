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

    // MARK: - Sender listener

    private let denied = NWError.dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied))
    private let listenerFailure = NWError.posix(.ENETDOWN)

    func test_listenerFailed_whileConnected_keepsTheCanvasAndRestartsQuietly() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }
        manager.connectionState = .connected(peerName: "Performer's iPhone")

        manager.handleListenerState(.failed(listenerFailure), code: "42")

        XCTAssertEqual(manager.connectionState, .connected(peerName: "Performer's iPhone"))
        XCTAssertEqual(scheduler.pendingCount, 1)
        scheduler.fire()
        XCTAssertEqual(manager.connectionState, .connected(peerName: "Performer's iPhone"))
        XCTAssertEqual(scheduler.pendingCount, 0)
    }

    func test_listenerFailed_whileReconnecting_alsoKeepsTheCanvas() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }
        manager.connectionState = .connected(peerName: "Performer's iPhone")
        manager.isReconnecting = true

        manager.handleListenerState(.failed(listenerFailure), code: "42")

        XCTAssertEqual(manager.connectionState, .connected(peerName: "Performer's iPhone"))
        XCTAssertEqual(scheduler.pendingCount, 1)
    }

    func test_listenerFailed_beforeAnyConnection_showsTheFailure() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .searching

        manager.handleListenerState(.failed(listenerFailure), code: "42")

        XCTAssertEqual(manager.connectionState, .failed)
        XCTAssertEqual(scheduler.pendingCount, 0)
    }

    func test_listenerFailedTwice_schedulesOneRestart() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }
        manager.connectionState = .connected(peerName: "Performer's iPhone")

        manager.handleListenerState(.failed(listenerFailure), code: "42")
        manager.handleListenerState(.failed(listenerFailure), code: "42")

        XCTAssertEqual(scheduler.pendingCount, 1)
    }

    func test_listenerRestarts_waitLongerEachTime_upToACap() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }
        manager.connectionState = .connected(peerName: "Performer's iPhone")

        for _ in 0..<5 {
            manager.handleListenerState(.failed(listenerFailure), code: "42")
            scheduler.fire()
        }

        XCTAssertEqual(scheduler.delays, [1, 2, 4, 5, 5])
    }

    func test_listenerReady_startsTheRestartPausesOver() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }
        manager.connectionState = .connected(peerName: "Performer's iPhone")

        manager.handleListenerState(.failed(listenerFailure), code: "42")
        scheduler.fire()
        manager.handleListenerState(.failed(listenerFailure), code: "42")
        scheduler.fire()
        manager.handleListenerState(.ready, code: "42")
        manager.handleListenerState(.failed(listenerFailure), code: "42")

        XCTAssertEqual(scheduler.delays, [1, 2, 1])
    }

    func test_stop_beforeTheListenerRestartFires_cancelsIt() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .connected(peerName: "Performer's iPhone")
        manager.handleListenerState(.failed(listenerFailure), code: "42")

        manager.stop()
        scheduler.fire()

        XCTAssertEqual(manager.connectionState, .idle)
    }

    func test_listenerWaitingWithPolicyDenied_beforeConnection_entersDeniedAfterTheDelay() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .searching

        manager.handleListenerState(.waiting(denied), code: "42")
        XCTAssertEqual(manager.connectionState, .searching)
        scheduler.fire()

        XCTAssertEqual(manager.connectionState, .localNetworkDenied)
    }

    func test_listenerRepeatedDeniedEvents_scheduleOneConfirmation() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .searching

        for _ in 0..<3 { manager.handleListenerState(.waiting(denied), code: "42") }

        XCTAssertEqual(scheduler.pendingCount, 1)
    }

    func test_listenerWaitingWithPolicyDenied_whileConnected_changesNothing() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .connected(peerName: "Performer's iPhone")

        manager.handleListenerState(.waiting(denied), code: "42")

        XCTAssertEqual(manager.connectionState, .connected(peerName: "Performer's iPhone"))
        XCTAssertEqual(scheduler.pendingCount, 0)
    }

    func test_listenerWaitingWithOtherError_doesNotEnterDenied() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .searching

        manager.handleListenerState(.waiting(listenerFailure), code: "42")

        XCTAssertEqual(manager.connectionState, .searching)
        XCTAssertEqual(scheduler.pendingCount, 0)
    }

    func test_listenerReady_afterDenied_resumesSearching() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .searching
        manager.handleListenerState(.waiting(denied), code: "42")
        scheduler.fire()
        XCTAssertEqual(manager.connectionState, .localNetworkDenied)

        manager.handleListenerState(.ready, code: "42")

        XCTAssertEqual(manager.connectionState, .searching)
    }

    func test_listenerReady_beforeTheDeniedDelay_cancelsTheConfirmation() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .searching
        manager.handleListenerState(.waiting(denied), code: "42")

        manager.handleListenerState(.ready, code: "42")
        scheduler.fire()

        XCTAssertEqual(manager.connectionState, .searching)
    }

    func test_deniedConfirmation_afterAConnectionArrived_doesNotCoverTheCanvas() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        manager.connectionState = .searching
        manager.handleListenerState(.waiting(denied), code: "42")

        manager.connectionState = .connected(peerName: "Performer's iPhone")
        scheduler.fire()

        XCTAssertEqual(manager.connectionState, .connected(peerName: "Performer's iPhone"))
    }

    // MARK: - Keepalive

    func test_tcpOptions_enableKeepaliveSoASilentPeerIsDetected() {
        let options = PhantomDrawSessionManager.makeTCPOptions()

        XCTAssertTrue(options.enableKeepalive)
        XCTAssertEqual(options.keepaliveIdle, 2)
        XCTAssertEqual(options.keepaliveInterval, 1)
        XCTAssertEqual(options.keepaliveCount, 3)
    }

    // MARK: - Sender: incoming candidates

    // Never started, so no real network is touched; the manager is driven through its state callbacks.
    private func makeIncoming() -> NWConnection {
        NWConnection(host: "127.0.0.1", port: 9, using: .tcp)
    }

    private func makeSenderWithActiveConnection(
        scheduler: FakeScheduler = FakeScheduler()
    ) -> (manager: PhantomDrawSessionManager, active: NWConnection, newConnections: () -> Int) {
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }
        var newConnections = 0
        manager.onNewConnection = { newConnections += 1 }
        let active = makeIncoming()
        XCTAssertTrue(manager.registerIncomingCandidate(active))
        manager.handleIncomingState(.ready, for: active)
        return (manager, active, { newConnections })
    }

    func test_incoming_whileConnected_isOnlyACandidate() {
        let (manager, _, newConnections) = makeSenderWithActiveConnection()
        let stateBefore = manager.connectionState

        XCTAssertTrue(manager.registerIncomingCandidate(makeIncoming()))

        XCTAssertEqual(manager.connectionState, stateBefore)
        XCTAssertFalse(manager.isReconnecting)
        XCTAssertEqual(newConnections(), 1)
    }

    func test_incomingCandidate_failedHandshake_leavesTheRunningConnectionAlone() {
        let (manager, active, newConnections) = makeSenderWithActiveConnection()
        let stateBefore = manager.connectionState
        let stranger = makeIncoming()
        XCTAssertTrue(manager.registerIncomingCandidate(stranger))

        manager.handleIncomingState(.failed(listenerFailure), for: stranger)

        XCTAssertEqual(manager.connectionState, stateBefore)
        XCTAssertFalse(manager.isReconnecting)
        XCTAssertEqual(newConnections(), 1)
        XCTAssertTrue(manager.registerIncomingCandidate(makeIncoming()))
        // The first connection is still the active one.
        manager.handleIncomingState(.failed(listenerFailure), for: active)
        XCTAssertTrue(manager.isReconnecting)
    }

    func test_incomingCandidate_ready_replacesTheOldConnection() {
        let (manager, old, newConnections) = makeSenderWithActiveConnection()
        let replacement = makeIncoming()
        XCTAssertTrue(manager.registerIncomingCandidate(replacement))

        manager.handleIncomingState(.ready, for: replacement)

        XCTAssertEqual(newConnections(), 2)
        XCTAssertFalse(manager.isReconnecting)
        // The old connection's own teardown is stale now and must not look like a lost connection.
        manager.handleIncomingState(.cancelled, for: old)
        XCTAssertFalse(manager.isReconnecting)
        manager.handleIncomingState(.failed(listenerFailure), for: replacement)
        XCTAssertTrue(manager.isReconnecting)
    }

    func test_incomingCandidate_ready_afterTheOldOneDropped_connectsAgain() {
        let (manager, old, newConnections) = makeSenderWithActiveConnection()
        manager.handleIncomingState(.failed(listenerFailure), for: old)
        XCTAssertTrue(manager.isReconnecting)
        let replacement = makeIncoming()
        XCTAssertTrue(manager.registerIncomingCandidate(replacement))

        manager.handleIncomingState(.ready, for: replacement)

        XCTAssertFalse(manager.isReconnecting)
        XCTAssertEqual(newConnections(), 2)
        if case .connected = manager.connectionState {} else { XCTFail("Expected .connected, got \(manager.connectionState)") }
    }

    func test_secondIncoming_whileACandidateIsPending_isRejected() {
        let manager = PhantomDrawSessionManager(scheduler: FakeScheduler())
        addTeardownBlock { manager.stop() }

        XCTAssertTrue(manager.registerIncomingCandidate(makeIncoming()))
        XCTAssertFalse(manager.registerIncomingCandidate(makeIncoming()))
    }

    func test_incomingCandidate_timeout_freesTheSlot() {
        let scheduler = FakeScheduler()
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }
        XCTAssertTrue(manager.registerIncomingCandidate(makeIncoming()))

        scheduler.fire()

        XCTAssertEqual(scheduler.delays, [10])
        XCTAssertTrue(manager.registerIncomingCandidate(makeIncoming()))
    }

    func test_incomingCandidate_timeoutAfterItBecameActive_changesNothing() {
        let scheduler = FakeScheduler()
        let (manager, active, _) = makeSenderWithActiveConnection(scheduler: scheduler)
        let stateBefore = manager.connectionState

        scheduler.fire()

        XCTAssertEqual(manager.connectionState, stateBefore)
        XCTAssertFalse(manager.isReconnecting)
        manager.handleIncomingState(.failed(listenerFailure), for: active)
        XCTAssertTrue(manager.isReconnecting)
    }

    func test_stop_dropsThePendingCandidate() {
        let manager = PhantomDrawSessionManager(scheduler: FakeScheduler())
        var newConnections = 0
        manager.onNewConnection = { newConnections += 1 }
        let candidate = makeIncoming()
        XCTAssertTrue(manager.registerIncomingCandidate(candidate))

        manager.stop()
        manager.handleIncomingState(.ready, for: candidate)

        XCTAssertEqual(manager.connectionState, .idle)
        XCTAssertEqual(newConnections, 0)
        XCTAssertTrue(manager.registerIncomingCandidate(makeIncoming()))
        manager.stop()
    }

    func test_incoming_beforeAnyConnection_failedHandshakeKeepsSearching() {
        let manager = PhantomDrawSessionManager(scheduler: FakeScheduler())
        addTeardownBlock { manager.stop() }
        manager.connectionState = .searching
        let stranger = makeIncoming()
        XCTAssertTrue(manager.registerIncomingCandidate(stranger))

        manager.handleIncomingState(.failed(listenerFailure), for: stranger)

        XCTAssertEqual(manager.connectionState, .searching)
        XCTAssertFalse(manager.isReconnecting)
    }

    func test_incoming_beforeAnyConnection_ready_connects() {
        let manager = PhantomDrawSessionManager(scheduler: FakeScheduler())
        addTeardownBlock { manager.stop() }
        manager.connectionState = .searching
        let candidate = makeIncoming()
        XCTAssertTrue(manager.registerIncomingCandidate(candidate))

        manager.handleIncomingState(.ready, for: candidate)

        if case .connected = manager.connectionState {} else { XCTFail("Expected .connected, got \(manager.connectionState)") }
    }

    func test_staleCandidateEvents_afterItWasDropped_areIgnored() {
        let manager = PhantomDrawSessionManager(scheduler: FakeScheduler())
        addTeardownBlock { manager.stop() }
        var newConnections = 0
        manager.onNewConnection = { newConnections += 1 }
        manager.connectionState = .searching
        let candidate = makeIncoming()
        XCTAssertTrue(manager.registerIncomingCandidate(candidate))
        manager.handleIncomingState(.failed(listenerFailure), for: candidate)

        manager.handleIncomingState(.ready, for: candidate)

        XCTAssertEqual(manager.connectionState, .searching)
        XCTAssertEqual(newConnections, 0)
    }

    // MARK: - Session ended by the peer

    private func makeReceiverWithActiveConnection(
        scheduler: FakeScheduler = FakeScheduler()
    ) -> (manager: PhantomDrawSessionManager, active: NWConnection) {
        let manager = PhantomDrawSessionManager(scheduler: scheduler)
        addTeardownBlock { manager.stop() }
        manager.startAsReceiver(code: "42")
        let active = NWConnection(host: "127.0.0.1", port: 9, using: .tcp)
        manager.handleCandidateState(.ready, for: active)
        return (manager, active)
    }

    func test_peerClosed_onReceiver_endsTheSessionWithoutReconnecting() {
        let scheduler = FakeScheduler()
        let (manager, active) = makeReceiverWithActiveConnection(scheduler: scheduler)

        manager.handlePeerClosed(active)

        XCTAssertEqual(manager.connectionState, .ended)
        XCTAssertFalse(manager.isReconnecting)
        // The search timer from before must not turn the ended session into a failure.
        scheduler.fire()
        XCTAssertEqual(manager.connectionState, .ended)
    }

    func test_connectionDrop_onReceiver_stillReconnects() {
        let (manager, active) = makeReceiverWithActiveConnection()

        manager.handleCandidateState(.failed(listenerFailure), for: active)

        XCTAssertTrue(manager.isReconnecting)
        if case .connected = manager.connectionState {} else { XCTFail("Expected .connected, got \(manager.connectionState)") }
    }

    func test_peerClosed_forAConnectionThatIsNotActive_changesNothing() {
        let (manager, _) = makeReceiverWithActiveConnection()
        let stateBefore = manager.connectionState

        manager.handlePeerClosed(NWConnection(host: "127.0.0.1", port: 9, using: .tcp))

        XCTAssertEqual(manager.connectionState, stateBefore)
        XCTAssertFalse(manager.isReconnecting)
    }

    func test_peerClosed_onSender_doesNotEndTheSession() {
        let manager = PhantomDrawSessionManager(scheduler: FakeScheduler())
        addTeardownBlock { manager.stop() }
        manager.connectionState = .connected(peerName: "Performer's iPhone")

        manager.handlePeerClosed(NWConnection(host: "127.0.0.1", port: 9, using: .tcp))

        XCTAssertEqual(manager.connectionState, .connected(peerName: "Performer's iPhone"))
    }

    func test_stop_afterTheSessionEnded_returnsToIdle() {
        let (manager, active) = makeReceiverWithActiveConnection()
        manager.handlePeerClosed(active)

        manager.stop()

        XCTAssertEqual(manager.connectionState, .idle)
    }

    func test_tryAgain_afterTheSessionEnded_searchesAgain() {
        let (manager, active) = makeReceiverWithActiveConnection()
        manager.handlePeerClosed(active)

        manager.startAsReceiver(code: "42")

        XCTAssertEqual(manager.connectionState, .searching)
    }
}

private final class FakeScheduler: DelayedActionScheduling {
    private var scheduledActions: [Completion] = []
    private(set) var delays: [TimeInterval] = []

    func schedule(after delay: TimeInterval, action: @escaping Completion) {
        delays.append(delay)
        scheduledActions.append(action)
    }

    var pendingCount: Int { scheduledActions.count }

    // Fires the oldest pending action by default; pass the index to fire a later one.
    func fire(at index: Int = 0) {
        guard scheduledActions.indices.contains(index) else { return }
        scheduledActions.remove(at: index)()
    }
}
