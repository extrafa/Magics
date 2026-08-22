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
    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            processingIcon
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
                .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.06), value: appeared)

            Spacer()

            VStack(spacing: 10) {
                Text(String(localized: "onboarding.processing.title"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.18), value: appeared)

                Text(isDone ? String(localized: "onboarding.processing.done") : phases[phaseIndex])
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .id(isDone ? -1 : phaseIndex)
                    .transition(.opacity)
                    .frame(minHeight: 44, alignment: .top)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.25), value: appeared)
            }

            progressBar
                .padding(.top, 28)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.32), value: appeared)

            Spacer().frame(height: 24)

            OnboardingCTAButton(
                title: String(localized: "onboarding.processing.cta"),
                action: onComplete
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(isButtonVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.35), value: isButtonVisible)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(milliseconds: 240)
                appeared = true
                schedulePhaseAdvance()
                try? await Task.sleep(milliseconds: 350)
                breathing = true
            }
        }
    }

    private var processingIcon: some View {
        ZStack {
            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.primaryText)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 72, weight: .regular))
                    .foregroundStyle(.primaryText)
                    .opacity(breathing ? 1.0 : 0.35)
                    .scaleEffect(breathing ? 1.08 : 0.94)
                    .animation(
                        .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: breathing
                    )
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: isDone)
        .frame(width: 110, height: 110)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primaryText.opacity(0.12))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.primaryText)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 1.2), value: progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 48)
    }

    private func schedulePhaseAdvance() {
        Task { @MainActor in
            let total = CGFloat(phases.count + 1)
            withAnimation(.easeInOut(duration: 1.8)) { progress = 1.0 / total }

            for i in 1..<phases.count {
                try? await Task.sleep(milliseconds: 2200)
                withAnimation(.easeInOut(duration: 0.4)) { phaseIndex = i }
                withAnimation(.easeInOut(duration: 1.2)) { progress = CGFloat(i + 1) / total }
            }
            try? await Task.sleep(milliseconds: 2200)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { isDone = true }
            withAnimation(.easeInOut(duration: 1.2)) { progress = 1.0 }
            try? await Task.sleep(milliseconds: 800)
            withAnimation(.easeOut(duration: 0.35)) { isButtonVisible = true }
        }
    }
}

#Preview {
    OBProcessingScreen(
        phases: ["Getting the party tricks ready…", "Picking tricks that need no setup…"],
        onComplete: {}
    )
    .background(Color.background)
}
