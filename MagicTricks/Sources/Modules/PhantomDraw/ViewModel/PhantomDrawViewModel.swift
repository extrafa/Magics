//
//  PhantomDrawViewModel.swift
//  Magic Tricks
//

import SwiftUI

@MainActor
final class PhantomDrawViewModel: ObservableObject {

    private static let minPointDistance: CGFloat = 2
    private static let progressSendInterval: TimeInterval = 0.05

    @Published var role: PhantomDrawRole?
    @Published var currentStroke: [CGPoint] = []
    @Published var completedStrokes: [DrawingStroke] = []
    @Published private(set) var totalDrawnLength: CGFloat = 0

    let session: PhantomDrawSessioning

    private var canvasSize: CGSize = .zero
    private var lastStrokePoint: CGPoint?
    private var currentStrokeID = UUID()
    private var lastProgressSentAt: Date?

    init(session: PhantomDrawSessioning) {
        self.session = session
        session.onNewConnection = { [weak self] in
            guard let self, self.role == .sender else { return }
            self.session.send(.sync(self.completedStrokes))
        }
    }

    func selectRole(_ role: PhantomDrawRole) {
        self.role = role
        switch role {
        case .receiver: session.connectionState = .enteringCode
        case .sender:   session.startAsSender()
        }
    }

    func submitReceiverCode(_ code: String) {
        session.startAsReceiver(code: code)
    }

    func setCanvasSize(_ size: CGSize) {
        canvasSize = size
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
