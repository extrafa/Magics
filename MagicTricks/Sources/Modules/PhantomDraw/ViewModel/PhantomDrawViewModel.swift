//
//  PhantomDrawViewModel.swift
//  Magic Tricks
//

import SwiftUI

@MainActor
final class PhantomDrawViewModel: ObservableObject {

    private static let minPointDistance: CGFloat = 2
    private static let progressSendInterval: TimeInterval = 0.05
    private static let exitTapCount = 4
    private static let exitTapWindow: TimeInterval = 1

    @Published var role: PhantomDrawRole?
    @Published var currentStroke: [CGPoint] = []
    @Published var completedStrokes: [DrawingStroke] = []
    @Published private(set) var totalDrawnLength: CGFloat = 0

    let session: PhantomDrawSessioning

    private var canvasSize: CGSize = .zero
    private var lastStrokePoint: CGPoint?
    private var currentStrokeID = UUID()
    private var lastProgressSentAt: Date?
    private let clock: () -> Date
    private var trashTaps = 0
    private var lastTrashTapAt: Date?

    init(session: PhantomDrawSessioning, clock: @escaping () -> Date = Date.init) {
        self.session = session
        self.clock = clock
        session.onNewConnection = { [weak self] in
            guard let self, self.role == .sender else { return }
            self.session.send(.sync(self.completedStrokes))
            if let ratio = self.canvasAspectRatio {
                self.session.send(.canvasAspectRatio(ratio))
            }
        }
    }

    func selectRole(_ role: PhantomDrawRole) {
        self.role = role
        switch role {
        case .receiver: session.prepareForCodeEntry()
        case .sender:   session.startAsSender()
        }
    }

    func submitReceiverCode(_ code: String) {
        session.startAsReceiver(code: code)
    }

    func setCanvasSize(_ size: CGSize) {
        canvasSize = size
        guard let ratio = canvasAspectRatio else { return }
        session.send(.canvasAspectRatio(ratio))
    }

    private var canvasAspectRatio: Double? {
        guard canvasSize.height > 0 else { return nil }
        return canvasSize.width / canvasSize.height
    }

    func addPoint(_ point: CGPoint) {
        if currentStroke.isEmpty {
            currentStrokeID = UUID()
            lastProgressSentAt = nil
        }
        if let last = lastStrokePoint {
            let dx = point.x - last.x
            let dy = point.y - last.y
            let distance = sqrt(dx * dx + dy * dy)
            guard distance >= Self.minPointDistance else { return }
            totalDrawnLength += distance
        }
        lastStrokePoint = point
        currentStroke.append(point)
        sendProgressIfNeeded()
    }

    func commitStroke() {
        guard !currentStroke.isEmpty else { return }
        let normalized = currentStroke.map { DrawingPoint(normalizing: $0, in: canvasSize) }
        let stroke = DrawingStroke(id: currentStrokeID, points: normalized)
        completedStrokes.append(stroke)
        session.send(.stroke(stroke))
        currentStroke = []
        lastStrokePoint = nil
        lastProgressSentAt = nil
    }

    private func sendProgressIfNeeded() {
        let now = Date()
        if let lastProgressSentAt, now.timeIntervalSince(lastProgressSentAt) < Self.progressSendInterval {
            return
        }
        lastProgressSentAt = now
        let normalized = currentStroke.map { DrawingPoint(normalizing: $0, in: canvasSize) }
        session.send(.strokeProgress(DrawingStroke(id: currentStrokeID, points: normalized)))
    }

    // Clears the canvas like the trash always did. Four quick taps in a row also say the trick should close:
    // the spectator's screen has no visible way out, so this is the performer's.
    func trashTapped() -> Bool {
        clearDrawing()
        let tappedAt = clock()
        if let lastTrashTapAt, tappedAt.timeIntervalSince(lastTrashTapAt) <= Self.exitTapWindow {
            trashTaps += 1
        } else {
            trashTaps = 1
        }
        lastTrashTapAt = tappedAt
        guard trashTaps >= Self.exitTapCount else { return false }
        trashTaps = 0
        lastTrashTapAt = nil
        return true
    }

    func clearDrawing() {
        completedStrokes = []
        currentStroke = []
        totalDrawnLength = 0
        lastStrokePoint = nil
        session.send(.clear)
    }

    func stop() {
        session.stop()
        role = nil
        completedStrokes = []
        currentStroke = []
        totalDrawnLength = 0
        lastStrokePoint = nil
    }
}
