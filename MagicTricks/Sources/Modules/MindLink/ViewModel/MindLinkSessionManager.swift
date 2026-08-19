//
//  MindLinkSessionManager.swift
//  Magic Tricks
//

import Foundation
import Network

@MainActor
final class MindLinkSessionManager: ObservableObject {

    private static let bonjourType = "_mindlink-magic._tcp"

    @Published var connectionState: MindLinkConnectionState = .idle
    @Published var receivedStrokes: [DrawingStroke] = []

    /// True only on the sender side: connection dropped but listener is still running.
    /// The sender canvas stays visible; a banner is shown instead.
    @Published var isReconnecting = false

    /// Called on the main thread the moment a fresh connection becomes ready.
    /// The sender uses this to push a full-sync of current strokes to the new peer.
    var onNewConnection: (() -> Void)?

    private enum CurrentRole { case sender, receiver }
    private var currentRole: CurrentRole = .receiver

    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?

    // MARK: - Public API

    func startAsReceiver() {
        teardown()
        currentRole = .receiver
        isReconnecting = false
        connectionState = .searching
        startBrowsing()
    }

    func startAsSender() {
        teardown()
        currentRole = .sender
        isReconnecting = false
        connectionState = .searching
        startListening()
    }

    func send(_ message: MindLinkMessage) {
        guard let connection,
              let data = try? JSONEncoder().encode(message) else { return }
        sendFramed(data, over: connection)
    }

    func stop() {
        teardown()
        isReconnecting = false
        connectionState = .idle
        receivedStrokes = []
    }

    // MARK: - Sender: persistent listener

    private func startListening() {
        listener?.cancel()
        let params = makeParams()
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
                // Accept only if searching or reconnecting; reject if already connected
                if case .connected = self.connectionState, !self.isReconnecting {
                    conn.cancel()
                    return
                }
                self.connection?.cancel()
                self.activate(conn)
            }
        }
        listener = l
        l.start(queue: .main)
    }

    // MARK: - Receiver: auto-restart browser

    private func startBrowsing() {
        browser?.cancel()
        let params = makeParams()
        let b = NWBrowser(for: .bonjour(type: Self.bonjourType, domain: nil), using: params)
        b.browseResultsChangedHandler = { [weak self] results, _ in
            DispatchQueue.main.async { [weak self] in
                // Guard against double-connection if handler fires multiple times
                guard let self, self.connection == nil, let result = results.first else { return }
                self.browser?.cancel()
                self.browser = nil
                let conn = NWConnection(to: result.endpoint, using: params)
                self.activate(conn)
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

    // MARK: - Connection lifecycle

    private func activate(_ conn: NWConnection) {
        connection = conn
        conn.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                switch state {
                case .ready:
                    // Guard: ignore if a newer connection has already replaced this one.
                    guard self.connection === conn else { return }
                    self.isReconnecting = false
                    self.connectionState = .connected(peerName: conn.endpoint.peerName)
                    self.receiveLoop(conn)
                    self.onNewConnection?()

                case .failed, .cancelled:
                    // Guard: stale handlers from old connections must not overwrite
                    // self.connection or self.isReconnecting for the new live connection.
                    guard self.connection === conn else { return }
                    self.connection = nil
                    switch self.currentRole {
                    case .sender:
                        self.isReconnecting = true
                    case .receiver:
                        self.connectionState = .searching
                        self.startBrowsing()
                    }

                default:
                    break
                }
            }
        }
        conn.start(queue: .main)
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
                // Remote sent FIN (done) or connection errored — cancel so that
                // stateUpdateHandler fires and reconnect logic runs.
                if done || error != nil { conn.cancel() }
                return
            }
            let length = header.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            guard length > 0, length < 1_000_000 else { self.receiveLoop(conn); return }

            conn.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { [weak self] body, _, done2, error2 in
                guard let self, let body, !done2, error2 == nil else {
                    if done2 || error2 != nil { conn.cancel() }
                    return
                }
                if let msg = try? JSONDecoder().decode(MindLinkMessage.self, from: body) {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        switch msg {
                        case .stroke(let s):    self.receivedStrokes.append(s)
                        case .clear:            self.receivedStrokes = []
                        case .sync(let all):    self.receivedStrokes = all
                        }
                    }
                }
                self.receiveLoop(conn)
            }
        }
    }

    // MARK: - Helpers

    private func makeParams() -> NWParameters {
        let p = NWParameters.tcp
        p.includePeerToPeer = true
        return p
    }

    private func teardown() {
        browser?.cancel()
        listener?.cancel()
        connection?.cancel()
        browser = nil
        listener = nil
        connection = nil
    }
}

private extension NWEndpoint {
    var peerName: String {
        if case .service(let name, _, _, _) = self { return name }
        return debugDescription
    }
}
