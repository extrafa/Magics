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

    let session = PhantomDrawSessionManager()

    private var canvasSize: CGSize = .zero
    private var sessionCancellable: AnyCancellable?

    init() {
        // Forward session's published changes so the view re-renders.
        sessionCancellable = session.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }

        // When a fresh connection arrives on the sender side, push all current strokes
        // so the receiver is immediately in sync (even after a reconnect).
        session.onNewConnection = { [weak self] in
            guard let self, self.role == .sender, !self.completedStrokes.isEmpty else { return }
            self.session.send(.sync(self.completedStrokes))
        }
    }

    func selectRole(_ role: PhantomDrawRole) {
        self.role = role
        switch role {
        case .receiver: session.startAsReceiver()
        case .sender:   session.startAsSender()
        }
    }

    func setCanvasSize(_ size: CGSize) {
        canvasSize = size
    }

    func addPoint(_ point: CGPoint) {
        currentStroke.append(point)
    }

    func commitStroke() {
        guard !currentStroke.isEmpty else { return }
        let normalized = currentStroke.map { DrawingPoint(normalizing: $0, in: canvasSize) }
        let stroke = DrawingStroke(id: UUID(), points: normalized)
        completedStrokes.append(stroke)
        session.send(.stroke(stroke))
        currentStroke = []
    }

    func clearDrawing() {
        completedStrokes = []
        currentStroke = []
        session.send(.clear)
    }

    func stop() {
        session.stop()
        role = nil
        completedStrokes = []
        currentStroke = []
    }
}
