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
                        context.drawStrokes(viewModel.completedStrokes, canvasSize: size)
                        context.drawActiveStroke(viewModel.currentStroke)
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
