//
//  OBProcessingScreen.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import SwiftUI

struct OBProcessingScreen: View {
    let phases: [String]
    let onComplete: () -> Void

    @State private var appeared = false
    @State private var breathing = false
    @State private var phaseIndex = 0
    @State private var isDone = false
    @State private var isButtonVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                ZStack {
                    if isDone {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.primaryText)
                            .transition(.scale(scale: 0.55).combined(with: .opacity))
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.primaryText.opacity(0.07))
                                .frame(width: 110, height: 110)
                                .scaleEffect(breathing ? 1.1 : 0.92)
                                .animation(
                                    .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                                    value: breathing
                                )

                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 44, weight: .regular))
                                .foregroundStyle(.primaryText)
                                .opacity(breathing ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                                    value: breathing
                                )
                        }
                        .transition(.opacity)
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.65), value: isDone)
                .frame(width: 110, height: 110)

                Text(isDone ? String(localized: "onboarding.processing.done") : phases[phaseIndex])
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primaryText)
                    .multilineTextAlignment(.center)
                    .id(isDone ? -1 : phaseIndex)
                    .transition(.opacity)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : -20)
            .animation(.spring(response: 0.55, dampingFraction: 0.82), value: appeared)

            Spacer()

            if isButtonVisible {
                OnboardingCTAButton(
                    title: String(localized: "onboarding.processing.cta"),
                    action: onComplete
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(240))
                appeared = true
                schedulePhaseAdvance()
                try? await Task.sleep(for: .milliseconds(350))
                breathing = true
            }
        }
    }

    private func schedulePhaseAdvance() {
        Task { @MainActor in
            for i in 1..<phases.count {
                try? await Task.sleep(for: .milliseconds(1100))
                withAnimation(.easeInOut(duration: 0.4)) { phaseIndex = i }
            }
            try? await Task.sleep(for: .milliseconds(1100))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { isDone = true }
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.easeOut(duration: 0.35)) { isButtonVisible = true }
        }
    }
}
