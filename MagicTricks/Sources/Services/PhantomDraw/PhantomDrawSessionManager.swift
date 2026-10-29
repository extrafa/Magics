//
//  PhantomDrawSessionManager.swift
//  Magic Tricks
//

import Foundation
import Network
import Security
import dnssd

// What PhantomDrawViewModel needs from the session, not the full Views-facing surface.
@MainActor
protocol PhantomDrawSessioning: AnyObject {
    var connectionState: PhantomDrawConnectionState { get set }
    var onNewConnection: Completion? { get set }

    func startAsReceiver(code: String)
    func prepareForCodeEntry()
    func startAsSender()
    func send(_ message: PhantomDrawMessage)
    func stop()
}

@MainActor
final class PhantomDrawSessionManager: ObservableObject, PhantomDrawSessioning {

    private static let bonjourType = "_phantomdraw._tcp"
    private static let pskIdentity = "PhantomDraw"
    private static let connectionTimeout: TimeInterval = 10
    private static let searchTimeout: TimeInterval = 15
    private static let deniedConfirmationDelay: TimeInterval = 1.5
    // The sender's listener is restarted silently with growing pauses, so a flaky network doesn't make it spin.
    private static let listenerRestartInitialDelay: TimeInterval = 1
    private static let listenerRestartMaxDelay: TimeInterval = 5

    // Peer-sent strokes are untrusted network input.
    nonisolated static let maxStrokes = 500
    nonisolated static let maxPointsPerStroke = 5_000

    @Published var connectionState: PhantomDrawConnectionState = .idle
    @Published var receivedStrokes: [DrawingStroke] = []
    @Published var inProgressStroke: DrawingStroke?
    @Published private(set) var pairingCode: String?
    @Published var senderCanvasAspectRatio: Double?

    @Published var isReconnecting = false

    // Bumped on every new search and on teardown, so a timer from an earlier search can't fail a later one.
    private var searchGeneration = 0
    // Same idea for the "Local Network is off" screen: a denial is only shown if no .ready follows within the delay.
    private var deniedGeneration = 0
    private var isDeniedConfirmationPending = false
    // Bumped on teardown, so a restart scheduled for an earlier session can't revive its listener.
    private var listenerGeneration = 0
    private var isListenerRestartPending = false
    private var listenerRestartDelay = PhantomDrawSessionManager.listenerRestartInitialDelay

    var onNewConnection: Completion?

    // Connection receive/decode runs here, off main, so a large .sync frame doesn't hitch Canvas.
    private let netQueue = DispatchQueue(label: "phantomdraw.net")

    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var receiverCode: String?
    private var waitingTimeoutWorkItem: DispatchWorkItem?
    private var candidateConnections: [NWConnection] = []
    private var candidateTimeouts: [ObjectIdentifier: DispatchWorkItem] = [:]
    private let scheduler: DelayedActionScheduling

    init(scheduler: DelayedActionScheduling = DispatchQueueScheduler()) {
        self.scheduler = scheduler
    }

    // MARK: - Public API

    func startAsReceiver(code: String) {
        teardown()
        isReconnecting = false
        receiverCode = code
        connectionState = .searching
        startBrowsing(code: code)
        scheduleSearchTimeout()
    }

    // Back to code entry: stops any search still running, so a late answer to the system prompt can't connect behind the screen.
    func prepareForCodeEntry() {
        teardown()
        isReconnecting = false
        connectionState = .enteringCode
    }

    func startAsSender() {
        teardown()
        isReconnecting = false
        let code = String(format: "%02d", Int.random(in: 0..<100))
        pairingCode = code
        connectionState = .searching
        startListening(code: code)
    }

    func send(_ message: PhantomDrawMessage) {
        guard let connection,
              let frame = try? PhantomDrawFraming.encode(message) else { return }
        connection.send(content: frame, completion: .idempotent)
    }

    func stop() {
        teardown()
        isReconnecting = false
        connectionState = .idle
        receivedStrokes = []
        senderCanvasAspectRatio = nil
        pairingCode = nil
    }

    // MARK: - Sender: persistent listener

    // `silent` is a restart in the middle of a show: nothing the spectator sees may change, so a failure to create the
    // listener is just retried later instead of becoming `.failed`.
    private func startListening(code: String, silent: Bool = false) {
        listener?.cancel()
        let params = makeParams(code: code)
        guard let l = try? NWListener(using: params) else {
            if silent {
                scheduleListenerRestart(code: code)
            } else {
                connectionState = .failed
            }
            return
        }
        l.service = NWListener.Service(type: Self.bonjourType)
        l.stateUpdateHandler = { [weak self, weak l] state in
            Task { @MainActor [weak self, weak l] in
                // A listener that was already replaced or torn down must not change the session.
                guard let self, let l, self.listener === l else { return }
                self.handleListenerState(state, code: code)
            }
        }
        l.newConnectionHandler = { [weak self] conn in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if case .connected = self.connectionState, !self.isReconnecting {
                    conn.cancel()
                    return
                }
                self.connection?.cancel()
                self.activateIncomingConnection(conn)
            }
        }
        listener = l
        l.start(queue: .main)
    }

    // Not private: driven directly in tests.
    func handleListenerState(_ state: NWListener.State, code: String) {
        switch state {
        case .failed:
            // Mid-show the canvas must stay a canvas: restart quietly with the same code instead of showing an error.
            guard isConnected else {
                connectionState = .failed
                return
            }
            scheduleListenerRestart(code: code)
        case .waiting(let error) where Self.isLocalNetworkDenied(error):
            // Once the spectator's phone is connected the show goes on; before that the performer has to hear about it.
            guard !isConnected else { return }
            confirmLocalNetworkDenied()
        case .ready:
            listenerRestartDelay = Self.listenerRestartInitialDelay
            cancelDeniedConfirmation()
            guard connectionState == .localNetworkDenied else { return }
            connectionState = .searching
        default:
            break
        }
    }

    private var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    private func scheduleListenerRestart(code: String) {
        guard !isListenerRestartPending else { return }
        isListenerRestartPending = true
        let generation = listenerGeneration
        let delay = listenerRestartDelay
        listenerRestartDelay = min(delay * 2, Self.listenerRestartMaxDelay)
        scheduler.schedule(after: delay) { [weak self] in
            guard let self, generation == self.listenerGeneration else { return }
            self.isListenerRestartPending = false
            self.startListening(code: code, silent: true)
        }
    }

    // MARK: - Receiver: auto-restart browser

    private func startBrowsing(code: String) {
        browser?.cancel()
        let params = makeParams(code: code)
        let b = NWBrowser(for: .bonjour(type: Self.bonjourType, domain: nil), using: params)
        b.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor [weak self] in
                guard let self, self.connection == nil, !results.isEmpty else { return }
                self.browser?.cancel()
                self.browser = nil
                self.raceConnections(to: results.map(\.endpoint), params: params)
            }
        }
        b.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                self?.handleBrowserState(state)
            }
        }
        browser = b
        b.start(queue: .main)
    }

    // Not private: driven directly in tests.
    func handleBrowserState(_ state: NWBrowser.State) {
        switch state {
        case .failed:
            connectionState = .failed
        case .waiting(let error) where Self.isLocalNetworkDenied(error):
            // Keep the browser running: the system prompt may still be open, and .ready follows if the user allows.
            confirmLocalNetworkDenied()
        case .ready:
            cancelDeniedConfirmation()
            guard connectionState == .localNetworkDenied else { return }
            connectionState = .searching
            scheduleSearchTimeout()
        default:
            break
        }
    }

    // The system can report a denial before the user has answered its prompt, so wait a moment before saying it's off.
    private func confirmLocalNetworkDenied() {
        guard !isDeniedConfirmationPending else { return }
        isDeniedConfirmationPending = true
        deniedGeneration += 1
        let generation = deniedGeneration
        scheduler.schedule(after: Self.deniedConfirmationDelay) { [weak self] in
            guard let self, generation == self.deniedGeneration else { return }
            self.isDeniedConfirmationPending = false
            // A connection that arrived meanwhile wins; a receiver that is only reconnecting still gets the screen.
            if self.isConnected && !self.isReconnecting { return }
            self.isReconnecting = false
            self.connectionState = .localNetworkDenied
        }
    }

    private func cancelDeniedConfirmation() {
        deniedGeneration += 1
        isDeniedConfirmationPending = false
    }

    nonisolated static func isLocalNetworkDenied(_ error: NWError) -> Bool {
        guard case .dns(let code) = error else { return false }
        return code == DNSServiceErrorType(kDNSServiceErr_PolicyDenied)
    }

    // The pairing code is only checked at the TLS/PSK handshake, not visible via Bonjour discovery - if more than one sender is nearby, connect to every candidate and keep whichever one's code actually matches.
    private func raceConnections(to endpoints: [NWEndpoint], params: NWParameters) {
        let connections = endpoints.map { NWConnection(to: $0, using: params) }
        candidateConnections = connections
        for conn in connections {
            conn.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    self?.handleCandidateState(state, for: conn)
                }
            }
            conn.start(queue: netQueue)
        }
    }

    private func handleCandidateState(_ state: NWConnection.State, for conn: NWConnection) {
        switch state {
        case .ready:
            guard connection == nil else { conn.cancel(); return }
            cancelCandidateTimeout(for: conn)
            for loser in candidateConnections where loser !== conn { loser.cancel() }
            candidateConnections = []
            connection = conn
            isReconnecting = false
            connectionState = .connected(peerName: conn.endpoint.peerName)
            receiveLoop(conn)
            onNewConnection?()

        case .waiting:
            scheduleCandidateTimeout(for: conn)

        case .failed, .cancelled:
            cancelCandidateTimeout(for: conn)
            if connection === conn {
                handleActiveConnectionLost()
                return
            }
            // A stale callback from a candidate teardown() already cancelled and dropped - ignore it.
            guard candidateConnections.contains(where: { $0 === conn }) else { return }
            candidateConnections.removeAll { $0 === conn }
            guard connection == nil, candidateConnections.isEmpty else { return }
            // Mid-reconnect, a failed candidate just means "keep trying" - connectionState
            // stays .connected (with the badge) until the reconnect timeout gives up.
            if !isReconnecting {
                connectionState = .searching
            }
            if let receiverCode { startBrowsing(code: receiverCode) }

        default:
            break
        }
    }

    // A dropped active connection retries instead of bouncing straight back to role selection -
    // a brief Wi-Fi blip shouldn't lose the trick's progress. Not private: driven directly in tests.
    func handleActiveConnectionLost() {
        connection = nil
        isReconnecting = true
        if let receiverCode { startBrowsing(code: receiverCode) }
        scheduleSearchTimeout()
    }

    // Caps both the first search and a reconnect: a wrong code otherwise loops search -> handshake fails -> search forever.
    private func scheduleSearchTimeout() {
        searchGeneration += 1
        let generation = searchGeneration
        scheduler.schedule(after: Self.searchTimeout) { [weak self] in
            guard let self, generation == self.searchGeneration else { return }
            let isStillSearching = self.isReconnecting || (self.receiverCode != nil && self.connectionState == .searching)
            guard isStillSearching else { return }
            self.isReconnecting = false
            // Give up the search entirely instead of leaving a browser/candidates running in the background.
            self.browser?.cancel()
            self.browser = nil
            self.candidateConnections.forEach { $0.cancel() }
            self.candidateConnections = []
            self.candidateTimeouts.values.forEach { $0.cancel() }
            self.candidateTimeouts.removeAll()
            self.connectionState = .failed
        }
    }

    private func scheduleCandidateTimeout(for conn: NWConnection) {
        let key = ObjectIdentifier(conn)
        guard candidateTimeouts[key] == nil else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.candidateTimeouts[key] = nil
            conn.cancel()
        }
        candidateTimeouts[key] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.connectionTimeout, execute: workItem)
    }

    private func cancelCandidateTimeout(for conn: NWConnection) {
        let key = ObjectIdentifier(conn)
        candidateTimeouts[key]?.cancel()
        candidateTimeouts[key] = nil
    }

    // MARK: - Sender: incoming connection lifecycle

    private func activateIncomingConnection(_ conn: NWConnection) {
        connection = conn
        cancelWaitingTimeout()
        conn.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch state {
                case .ready:
                    guard self.connection === conn else { return }
                    self.cancelWaitingTimeout()
                    self.isReconnecting = false
                    self.connectionState = .connected(peerName: conn.endpoint.peerName)
                    self.receiveLoop(conn)
                    self.onNewConnection?()

                case .waiting:
                    guard self.connection === conn else { return }
                    self.scheduleWaitingTimeout(for: conn)

                case .failed, .cancelled:
                    guard self.connection === conn else { return }
                    self.cancelWaitingTimeout()
                    self.connection = nil
                    self.isReconnecting = true

                default:
                    break
                }
            }
        }
        conn.start(queue: netQueue)
    }

    // A connection with no viable path (e.g. AWDL out of range) can sit in .waiting indefinitely on its own.
    private func scheduleWaitingTimeout(for conn: NWConnection) {
        guard waitingTimeoutWorkItem == nil else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.connection === conn else { return }
            self.waitingTimeoutWorkItem = nil
            conn.cancel()
        }
        waitingTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.connectionTimeout, execute: workItem)
    }

    private func cancelWaitingTimeout() {
        waitingTimeoutWorkItem?.cancel()
        waitingTimeoutWorkItem = nil
    }

    // MARK: - Framing

    nonisolated private func receiveLoop(_ conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] header, _, done, error in
            guard let self, let header, error == nil, !done else {
                if done || error != nil { conn.cancel() }
                return
            }
            guard let length = PhantomDrawFraming.bodyLength(header: header) else {
                conn.cancel()
                return
            }

            conn.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { [weak self] body, _, done2, error2 in
                guard let self, let body, !done2, error2 == nil else {
                    if done2 || error2 != nil { conn.cancel() }
                    return
                }
                guard let msg = try? PhantomDrawFraming.decode(body) else {
                    conn.cancel()
                    return
                }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    switch msg {
                    case .stroke(let s):
                        self.inProgressStroke = nil
                        guard self.receivedStrokes.count < Self.maxStrokes, let sanitized = self.sanitized(s) else { break }
                        self.receivedStrokes.append(sanitized)
                    case .strokeProgress(let s):
                        self.inProgressStroke = self.sanitized(s)
                    case .clear:
                        self.receivedStrokes = []
                        self.inProgressStroke = nil
                    case .sync(let all):
                        self.receivedStrokes = Array(all.compactMap(self.sanitized).prefix(Self.maxStrokes))
                        self.inProgressStroke = nil
                    case .canvasAspectRatio(let ratio):
                        guard ratio.isFinite, ratio > 0 else { break }
                        self.senderCanvasAspectRatio = ratio
                    }
                }
                self.receiveLoop(conn)
            }
        }
    }

    // MARK: - Helpers

    // Clamps a peer-sent stroke to sane bounds; nil if it's malformed enough to just drop.
    nonisolated func sanitized(_ stroke: DrawingStroke) -> DrawingStroke? {
        guard (1...Self.maxPointsPerStroke).contains(stroke.points.count) else { return nil }
        let clampedPoints = stroke.points.map {
            DrawingPoint(x: min(max($0.x, 0), 1), y: min(max($0.y, 0), 1))
        }
        return DrawingStroke(id: stroke.id, points: clampedPoints)
    }

    private func makeParams(code: String) -> NWParameters {
        let tlsOptions = NWProtocolTLS.Options()
        let secOptions = tlsOptions.securityProtocolOptions

        // Don't pin min TLS version - with the PSK below it forces TLS 1.3 anyway, but pinning it explicitly breaks the handshake.
        let keyBytes = Array(code.utf8)
        let identityBytes = Array(Self.pskIdentity.utf8)
        keyBytes.withUnsafeBytes { rawKey in
            identityBytes.withUnsafeBytes { rawIdentity in
                let key = DispatchData(bytes: rawKey)
                let identity = DispatchData(bytes: rawIdentity)
                sec_protocol_options_add_pre_shared_key(secOptions, key as __DispatchData, identity as __DispatchData)
            }
        }

        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = Int(Self.connectionTimeout)

        let p = NWParameters(tls: tlsOptions, tcp: tcpOptions)
        p.includePeerToPeer = true
        return p
    }

    private func teardown() {
        searchGeneration += 1
        listenerGeneration += 1
        isListenerRestartPending = false
        listenerRestartDelay = Self.listenerRestartInitialDelay
        cancelDeniedConfirmation()
        browser?.cancel()
        listener?.cancel()
        connection?.cancel()
        candidateConnections.forEach { $0.cancel() }
        candidateTimeouts.values.forEach { $0.cancel() }
        candidateTimeouts.removeAll()
        cancelWaitingTimeout()
        browser = nil
        listener = nil
        connection = nil
        receiverCode = nil
        candidateConnections = []
    }
}

private extension NWEndpoint {
    var peerName: String {
        if case .service(let name, _, _, _) = self { return name }
        return debugDescription
    }
}
