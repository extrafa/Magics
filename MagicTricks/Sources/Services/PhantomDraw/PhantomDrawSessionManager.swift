//
//  PhantomDrawSessionManager.swift
//  Magic Tricks
//

import Foundation
import Network
import Security

// What PhantomDrawViewModel needs from the session, not the full Views-facing surface.
@MainActor
protocol PhantomDrawSessioning: AnyObject {
    var connectionState: PhantomDrawConnectionState { get set }
    var onNewConnection: Completion? { get set }

    func startAsReceiver(code: String)
    func startAsSender()
    func send(_ message: PhantomDrawMessage)
    func stop()
}

@MainActor
final class PhantomDrawSessionManager: ObservableObject, PhantomDrawSessioning {

    private static let bonjourType = "_phantomdraw._tcp"
    private static let pskIdentity = "PhantomDraw"
    private static let connectionTimeout: TimeInterval = 10

    @Published var connectionState: PhantomDrawConnectionState = .idle
    @Published var receivedStrokes: [DrawingStroke] = []
    @Published var inProgressStroke: DrawingStroke?
    @Published private(set) var pairingCode: String?

    @Published var isReconnecting = false

    var onNewConnection: Completion?

    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var receiverCode: String?
    private var waitingTimeoutWorkItem: DispatchWorkItem?
    private var candidateConnections: [NWConnection] = []
    private var candidateTimeouts: [ObjectIdentifier: DispatchWorkItem] = [:]

    // MARK: - Public API

    func startAsReceiver(code: String) {
        teardown()
        isReconnecting = false
        receiverCode = code
        connectionState = .searching
        startBrowsing(code: code)
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
              let data = try? JSONEncoder().encode(message) else { return }
        sendFramed(data, over: connection)
    }

    func stop() {
        teardown()
        isReconnecting = false
        connectionState = .idle
        receivedStrokes = []
        pairingCode = nil
    }

    // MARK: - Sender: persistent listener

    private func startListening(code: String) {
        listener?.cancel()
        let params = makeParams(code: code)
        guard let l = try? NWListener(using: params) else {
            connectionState = .failed; return
        }
        l.service = NWListener.Service(type: Self.bonjourType)
        l.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                if case .failed = state { self?.connectionState = .failed }
            }
        }
        l.newConnectionHandler = { [weak self] conn in
            DispatchQueue.main.async { [weak self] in
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

    // MARK: - Receiver: auto-restart browser

    private func startBrowsing(code: String) {
        browser?.cancel()
        let params = makeParams(code: code)
        let b = NWBrowser(for: .bonjour(type: Self.bonjourType, domain: nil), using: params)
        b.browseResultsChangedHandler = { [weak self] results, _ in
            DispatchQueue.main.async { [weak self] in
                guard let self, self.connection == nil, !results.isEmpty else { return }
                self.browser?.cancel()
                self.browser = nil
                self.raceConnections(to: results.map(\.endpoint), params: params)
            }
        }
        b.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                if case .failed = state { self?.connectionState = .failed }
            }
        }
        browser = b
        b.start(queue: .main)
    }

    // The pairing code is only checked at the TLS/PSK handshake, not visible via Bonjour discovery - if more than one sender is nearby, connect to every candidate and keep whichever one's code actually matches.
    private func raceConnections(to endpoints: [NWEndpoint], params: NWParameters) {
        let connections = endpoints.map { NWConnection(to: $0, using: params) }
        candidateConnections = connections
        for conn in connections {
            conn.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async { [weak self] in
                    self?.handleCandidateState(state, for: conn)
                }
            }
            conn.start(queue: .main)
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
                // The connection was already established and then dropped - back to role selection
                // instead of silently re-searching forever (there's no timeout for "found nothing").
                connection = nil
                connectionState = .idle
                return
            }
            // A stale callback from a candidate teardown() already cancelled and dropped - ignore it.
            guard candidateConnections.contains(where: { $0 === conn }) else { return }
            candidateConnections.removeAll { $0 === conn }
            guard connection == nil, candidateConnections.isEmpty else { return }
            connectionState = .searching
            if let receiverCode { startBrowsing(code: receiverCode) }

        default:
            break
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
            DispatchQueue.main.async { [weak self] in
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
        conn.start(queue: .main)
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

    // MARK: - Framing (4-byte big-endian length prefix)

    private func sendFramed(_ data: Data, over conn: NWConnection) {
        var len = UInt32(data.count).bigEndian
        let frame = Data(bytes: &len, count: 4) + data
        conn.send(content: frame, completion: .idempotent)
    }

    private func receiveLoop(_ conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] header, _, done, error in
            guard let self, let header, header.count == 4, error == nil, !done else {
                if done || error != nil { conn.cancel() }
                return
            }
            let length = header.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self).bigEndian }
            guard length > 0, length < 1_000_000 else {
                conn.cancel()
                return
            }

            conn.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { [weak self] body, _, done2, error2 in
                guard let self, let body, !done2, error2 == nil else {
                    if done2 || error2 != nil { conn.cancel() }
                    return
                }
                guard let msg = try? JSONDecoder().decode(PhantomDrawMessage.self, from: body) else {
                    conn.cancel()
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    switch msg {
                    case .stroke(let s):
                        self.receivedStrokes.append(s)
                        self.inProgressStroke = nil
                    case .strokeProgress(let s):
                        self.inProgressStroke = s
                    case .clear:
                        self.receivedStrokes = []
                        self.inProgressStroke = nil
                    case .sync(let all):
                        self.receivedStrokes = all
                        self.inProgressStroke = nil
                    }
                }
                DispatchQueue.main.async { [weak self] in self?.receiveLoop(conn) }
            }
        }
    }

    // MARK: - Helpers

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
