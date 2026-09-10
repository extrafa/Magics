//
//  PhantomDrawSenderView.swift
//  Magic Tricks
//

import SwiftUI

struct PhantomDrawSenderView: View {

    @ObservedObject var viewModel: PhantomDrawViewModel
    @State private var isExitHintVisible: Bool
    @State private var statusBarHeight: CGFloat = 59

    init(viewModel: PhantomDrawViewModel, preferences: ExitHintPreferenceManaging = AppPreferences.shared) {
        self.viewModel = viewModel
        _isExitHintVisible = State(initialValue: preferences.isExitHintEnabled)
    }

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

            ExitHintView(isExitHintVisible: $isExitHintVisible, style: .specialWhite, skipsTraining: true)
                .padding(.top, statusBarHeight)
                .ignoresSafeArea(edges: .top)
        }
        .onAppear {
            // Nested inside PhantomDrawView's titled nav bar, so the inherited safe area is taller than just the status bar - same workaround as GeoMentalismView.
            statusBarHeight = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.keyWindow?.safeAreaInsets.top ?? 59
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: viewModel.clearDrawing) {
                    Image(systemName: "trash")
                        .foregroundStyle(.black)
                }
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.draw")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.black.opacity(0.18))
            Text(String(localized: "phantomDraw.drawAnythingPlaceholder"))
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.28))
        }
        .allowsHitTesting(false)
    }
}
