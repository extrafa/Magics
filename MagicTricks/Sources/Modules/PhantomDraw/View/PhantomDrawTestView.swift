//
//  PhantomDrawTestView.swift
//  Magic Tricks
//

import SwiftUI

struct PhantomDrawTestView: View {

    @State private var strokes: [DrawingStroke] = []
    @State private var currentPoints: [CGPoint] = []
    @State private var senderCanvasSize: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            receiverPanel
            divider
            senderPanel
        }
        .navigationTitle("Test Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    strokes = []
                    currentPoints = []
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .disabled(strokes.isEmpty && currentPoints.isEmpty)
            }
        }
    }

    // MARK: - Receiver (top)

    private var receiverPanel: some View {
        ZStack {
            Color.background

            if strokes.isEmpty && currentPoints.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Waiting for drawing...")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .padding(16)

            Canvas { context, size in
                renderStrokes(strokes, context: context, canvasSize: size)
                renderLiveStroke(currentPoints, context: context, canvasSize: senderCanvasSize, targetSize: size)
            }
            .padding(16)
            .allowsHitTesting(false)

            panelLabel("Your view", icon: "eye")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sender (bottom)

    private var senderPanel: some View {
        ZStack {
            Color.white

            if strokes.isEmpty && currentPoints.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(Color.black.opacity(0.18))
                    Text("Draw anything")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.3))
                }
                .allowsHitTesting(false)
            }

            GeometryReader { geo in
                Canvas { context, size in
                    renderStrokes(strokes, context: context, canvasSize: size)
                    renderLiveStrokeRaw(currentPoints, context: context)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            currentPoints.append(value.location)
                        }
                        .onEnded { _ in
                            commitStroke(canvasSize: geo.size)
                        }
                )
                .onAppear { senderCanvasSize = geo.size }
                .onChange(of: geo.size) { s in senderCanvasSize = s }
            }

            panelLabel("Spectator draws here", icon: "hand.draw")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Divider

    private var divider: some View {
        ZStack {
            Color.grayBorder.frame(height: 1)
            HStack(spacing: 6) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                Text("You see this")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                Spacer()
                Text("Spectator draws this")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.background)
        }
    }

    // MARK: - Helpers

    private func panelLabel(_ title: String, icon: String) -> some View {
        VStack {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 8)
            Spacer()
        }
    }

    private func commitStroke(canvasSize: CGSize) {
        guard !currentPoints.isEmpty else { return }
        let normalized = currentPoints.map { DrawingPoint(normalizing: $0, in: canvasSize) }
        strokes.append(DrawingStroke(id: UUID(), points: normalized))
        currentPoints = []
    }
}

// MARK: - Drawing helpers

private func renderStrokes(_ strokes: [DrawingStroke], context: GraphicsContext, canvasSize: CGSize) {
    for stroke in strokes {
        guard stroke.points.count > 1 else { continue }
        var path = Path()
        path.move(to: stroke.points[0].toCGPoint(in: canvasSize))
        for pt in stroke.points.dropFirst() { path.addLine(to: pt.toCGPoint(in: canvasSize)) }
        context.stroke(path, with: .color(.black), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
    }
}

private func renderLiveStroke(_ points: [CGPoint], context: GraphicsContext, canvasSize: CGSize, targetSize: CGSize) {
    guard points.count > 1, canvasSize.width > 0, canvasSize.height > 0 else { return }
    let scaleX = targetSize.width / canvasSize.width
    let scaleY = targetSize.height / canvasSize.height
    var path = Path()
    path.move(to: CGPoint(x: points[0].x * scaleX, y: points[0].y * scaleY))
    for pt in points.dropFirst() { path.addLine(to: CGPoint(x: pt.x * scaleX, y: pt.y * scaleY)) }
    context.stroke(path, with: .color(.black), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
}

private func renderLiveStrokeRaw(_ points: [CGPoint], context: GraphicsContext) {
    guard points.count > 1 else { return }
    var path = Path()
    path.move(to: points[0])
    for pt in points.dropFirst() { path.addLine(to: pt) }
    context.stroke(path, with: .color(.black), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
}
