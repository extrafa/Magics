//
//  PhantomDrawReceiverView.swift
//  Magic Tricks
//

import SwiftUI

struct PhantomDrawReceiverView: View {

    @ObservedObject var viewModel: PhantomDrawViewModel

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                        .padding(24)

                    if viewModel.session.receivedStrokes.isEmpty {
                        placeholder
                    }

                    Canvas { context, size in
                        drawStrokes(viewModel.session.receivedStrokes, context: context, canvasSize: size)
                    }
                    .padding(24)
                    .allowsHitTesting(false)
                }
            }
        }
        .navigationTitle("Phantom Draw")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                connectionBadge
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color.secondary.opacity(0.4))
            Text("Waiting for drawing...")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .allowsHitTesting(false)
    }

    private var connectionBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.green)
                .frame(width: 7, height: 7)
            Text("Connected")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
    // Note: receiver is never shown this view while reconnecting —
    // it transitions to .searching state and the session auto-reconnects.
}

private func drawStrokes(_ strokes: [DrawingStroke], context: GraphicsContext, canvasSize: CGSize) {
    for stroke in strokes {
        guard stroke.points.count > 1 else { continue }
        var path = Path()
        path.move(to: stroke.points[0].toCGPoint(in: canvasSize))
        for point in stroke.points.dropFirst() {
            path.addLine(to: point.toCGPoint(in: canvasSize))
        }
        context.stroke(
            path,
            with: .color(.black),
            style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
        )
    }
}
