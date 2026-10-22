//
//  TimeControlView.swift
//  Magic Tricks
//
//  Created by Ross on 23/08/2025.
//

import SwiftUI

struct TimeControlView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: TimeControlViewModel
    @ScaledMetric(relativeTo: .title3) private var scaledCircleSide: CGFloat = 84

    // Two circles share one row on a narrow screen, so the growth stops here.
    private var circleSide: CGFloat { min(scaledCircleSide, 140) }

    init(viewModel: TimeControlViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? TimeControlViewModel())
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Text(viewModel.formattedTime)
                    .font(.system(size: 62, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 20)

                Spacer()

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
            }
        }
        .exitHint(style: .specialWhite)
        .hapticsUnavailableNoticeOverlay()
        .keepsScreenAwake(while: viewModel.isRunning || viewModel.isTransmitting)
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            viewModel.handleSceneBecameActive()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var controls: some View {
        HStack {
            Button(action: viewModel.reset) {
                controlCircle(
                    title: String(localized: "timeControl.reset"),
                    fill: Color.white.opacity(0.12),
                    titleColor: .white
                )
            }
            .disabled(!viewModel.canReset)
            .opacity(viewModel.canReset ? 1 : 0.35)

            Spacer()

            Button(action: viewModel.handlePrimaryAction) {
                controlCircle(
                    title: viewModel.isRunning ? String(localized: "timeControl.stop") : String(localized: "timeControl.start"),
                    fill: viewModel.isRunning ? Color.red.opacity(0.22) : Color.green.opacity(0.22),
                    titleColor: viewModel.isRunning ? .red : .green
                )
            }
            .disabled(!viewModel.canUsePrimaryAction)
            .opacity(viewModel.hasReachedLimit ? 0.35 : 1)
        }
    }

    private func controlCircle(title: String, fill: Color, titleColor: Color) -> some View {
        ZStack {
            Circle()
                .fill(fill)
                .overlay { Circle().stroke(Color.white.opacity(0.08), lineWidth: 1) }
                .frame(width: circleSide, height: circleSide)

            Text(title)
                .font(.system(.title3, design: .rounded, weight: .regular))
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 8)
        }
    }
}

#Preview {
    TimeControlView()
}
