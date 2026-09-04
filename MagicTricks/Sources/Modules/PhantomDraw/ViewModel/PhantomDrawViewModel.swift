//
//  PhantomDrawViewModel.swift
//  Magic Tricks
//

import SwiftUI
import Combine

@MainActor
final class PhantomDrawViewModel: ObservableObject {

    @Published var role: PhantomDrawRole?
    @Published var currentStroke: [CGPoint] = []
    @Published var completedStrokes: [DrawingStroke] = []
    @Published private(set) var totalDrawnLength: CGFloat = 0

    let session = PhantomDrawSessionManager()

    private var canvasSize: CGSize = .zero
    private var sessionCancellable: AnyCancellable?
    private var lastStrokePoint: CGPoint?

    init() {
        sessionCancellable = session.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }

        session.onNewConnection = { [weak self] in
            guard let self, self.role == .sender, !self.completedStrokes.isEmpty else { return }
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
        if let last = lastStrokePoint {
            let dx = point.x - last.x
            let dy = point.y - last.y
            totalDrawnLength += sqrt(dx * dx + dy * dy)
        }
        lastStrokePoint = point
        currentStroke.append(point)
    }

    func commitStroke() {
        guard !currentStroke.isEmpty else { return }
        let normalized = currentStroke.map { DrawingPoint(normalizing: $0, in: canvasSize) }
        let stroke = DrawingStroke(id: UUID(), points: normalized)
        completedStrokes.append(stroke)
        session.send(.stroke(stroke))
        currentStroke = []
        lastStrokePoint = nil
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
