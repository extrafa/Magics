//
//  ExitHintView.swift
//  Magic Tricks
//
//  Created by Ross on 09/04/2026.
//

import SwiftUI

struct ExitHintView: View {
    @Binding var isVisible: Bool
    @Environment(\.dismiss) private var dismiss
    let style: ExitHintStyle

    @StateObject private var viewModel = ExitHintViewModel()

    init(isVisible: Binding<Bool>, style: ExitHintStyle = .normal) {
        _isVisible = isVisible
        self.style = style
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                exitHitArea
                hintOverlay
                    .opacity(isVisible ? viewModel.hintOpacity : 0)
            }
            .padding(.top, 10)
            .padding(.leading, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .exitHintLongPressEnabled(onExit: dismiss.callAsFunction)
        .alert(
            String(localized: "exitHint.confirm.title"),
            isPresented: $viewModel.isConfirmAlertPresented
        ) {
            Button(String(localized: "exitHint.showAgain"), role: .cancel) { }
            Button(String(localized: "common.gotIt")) {
                viewModel.confirmHintDismiss {
                    isVisible = false
                    dismiss()
                }
            }
        } message: {
            Text(String(localized: "exitHint.confirm.description"))
        }
        .onAppear {
            viewModel.configurePresentation(isVisible: isVisible, isHintVisible: $isVisible)
            syncGestureState()
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                viewModel.configurePresentation(isVisible: newValue, isHintVisible: $isVisible)
            } else {
                viewModel.cancelAutoFade()
            }
            syncGestureState()
        }
        .onChange(of: viewModel.isConfirmAlertPresented) { _, _ in
            syncGestureState()
        }
        .onDisappear {
            ExitHintGestureState.shared.isTrainingActive = false
            ExitHintGestureState.shared.onTrainingHold = nil
            ExitHintGestureState.shared.onOutsideTap = nil
        }
    }

    private var exitHitArea: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.clear)
            .frame(width: ExitHintZone.frame.width, height: ExitHintZone.frame.height)
            .allowsHitTesting(false)
    }

    private var hintOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    style.strokeColor,
                    style: StrokeStyle(lineWidth: 1.4, dash: [7, 5])
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    VStack(spacing: 0) {
                        Spacer(minLength: 18)

                        VStack(spacing: 6) {
                            Text(String(localized: "exitHint.holdHere"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Text(String(localized: "exitHint.exitAnyTrick"))
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                        }

                        Spacer()

                        Text(String(localized: "exitHint.tryHold"))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .opacity(0.9)
                    }
                    .foregroundStyle(style.textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
                .frame(width: ExitHintZone.frame.width, height: ExitHintZone.frame.height)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                ExitHintGestureState.shared.globalRect = proxy.frame(in: .global)
                            }
                            .onChange(of: proxy.frame(in: .global)) { _, newValue in
                                ExitHintGestureState.shared.globalRect = newValue
                            }
                    }
                }
                .allowsHitTesting(false)
        }
    }
    
    private func syncGestureState() {
        ExitHintGestureState.shared.isTrainingActive = isVisible && viewModel.shouldBlockInteraction
        ExitHintGestureState.shared.onTrainingHold = {
            viewModel.presentConfirmation()
        }
        ExitHintGestureState.shared.onOutsideTap = {
            viewModel.flashHint()
        }
    }
}

#Preview {
    ExitHintView(isVisible: .constant(true))
}
