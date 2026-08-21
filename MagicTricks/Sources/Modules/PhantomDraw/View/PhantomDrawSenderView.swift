//
//  PhantomDrawSenderView.swift
//  Magic Tricks
//

import SwiftUI

struct PhantomDrawSenderView: View {

    @ObservedObject var viewModel: PhantomDrawViewModel
    @State private var exitHintVisible = AppPreferences.shared.isExitHintEnabled

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    if viewModel.totalDrawnLength < 8 {
                        placeholder
                    }

                    Canvas { context, size in
                        drawStrokes(viewModel.completedStrokes, context: context, canvasSize: size, color: .black)
                        drawActiveStroke(viewModel.currentStroke, context: context, color: .black)
                    }
                    .ignoresSafeArea()
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                viewModel.addPoint(value.location)
                            }
                            .onEnded { _ in
                                viewModel.commitStroke()
                            }
                    )
                    .onAppear {
                        viewModel.setCanvasSize(geo.size)
                    }
                    .onChange(of: geo.size) { size in
                        viewModel.setCanvasSize(size)
                    }
                }
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .topLeading) {
            ExitHintView(isVisible: $exitHintVisible, style: .specialWhite)
        }
        .navigationTitle("Draw")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: viewModel.clearDrawing) {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.completedStrokes.isEmpty && viewModel.currentStroke.isEmpty)
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.draw")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.black.opacity(0.18))
            Text("Draw anything")
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.28))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Drawing helpers

private func drawStrokes(_ strokes: [DrawingStroke], context: GraphicsContext, canvasSize: CGSize, color: Color) {
    for stroke in strokes {
        guard stroke.points.count > 1 else { continue }
        var path = Path()
        path.move(to: stroke.points[0].toCGPoint(in: canvasSize))
        for point in stroke.points.dropFirst() {
            path.addLine(to: point.toCGPoint(in: canvasSize))
        }
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
        )
    }
}

private func drawActiveStroke(_ points: [CGPoint], context: GraphicsContext, color: Color) {
    guard points.count > 1 else { return }
    var path = Path()
    path.move(to: points[0])
    for point in points.dropFirst() {
        path.addLine(to: point)
    }
    context.stroke(
        path,
        with: .color(color),
        style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
    )
}
