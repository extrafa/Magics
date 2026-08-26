//
//  PhantomDrawSessionManager.swift
//  Magic Tricks
//

import Foundation
import Network
import Security

@MainActor
final class PhantomDrawSessionManager: ObservableObject {

    private static let bonjourType = "_phantomdraw._tcp"
    private static let pskIdentity = "PhantomDraw"

    @Published var connectionState: PhantomDrawConnectionState = .idle
    @Published var receivedStrokes: [DrawingStroke] = []
    @Published private(set) var pairingCode: String?

    @Published var isReconnecting = false

    var onNewConnection: (() -> Void)?

    private enum CurrentRole { case sender, receiver }
    private var currentRole: CurrentRole = .receiver

    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var receiverCode: String?

    // MARK: - Public API

    func startAsReceiver(code: String) {
        teardown()
        currentRole = .receiver
        isReconnecting = false
        receiverCode = code
        connectionState = .searching
        startBrowsing(code: code)
    }

    func startAsSender() {
        teardown()
        currentRole = .sender
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
                self.activate(conn)
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
                    guard self.connection === conn else { return }
                    self.isReconnecting = false
                    self.connectionState = .connected(peerName: conn.endpoint.peerName)
                    self.receiveLoop(conn)
                    self.onNewConnection?()

                case .failed, .cancelled:
                    guard self.connection === conn else { return }
                    self.connection = nil
                    switch self.currentRole {
                    case .sender:
                        self.isReconnecting = true
                    case .receiver:
                        self.connectionState = .searching
                        if let receiverCode = self.receiverCode {
                            self.startBrowsing(code: receiverCode)
                        }
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
                    case .stroke(let s):    self.receivedStrokes.append(s)
                    case .clear:            self.receivedStrokes = []
                    case .sync(let all):    self.receivedStrokes = all
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

        // Don't pin min TLS version — with the PSK below it forces TLS 1.3 anyway, but pinning it explicitly breaks the handshake.
        let keyBytes = Array(code.utf8)
        let identityBytes = Array(Self.pskIdentity.utf8)
        keyBytes.withUnsafeBytes { rawKey in
            identityBytes.withUnsafeBytes { rawIdentity in
                let key = DispatchData(bytes: rawKey)
                let identity = DispatchData(bytes: rawIdentity)
                sec_protocol_options_add_pre_shared_key(secOptions, key as __DispatchData, identity as __DispatchData)
            }
        }

        let p = NWParameters(tls: tlsOptions, tcp: NWProtocolTCP.Options())
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
        receiverCode = nil
    }
}

private extension NWEndpoint {
    var peerName: String {
        if case .service(let name, _, _, _) = self { return name }
        return debugDescription
    }
}
