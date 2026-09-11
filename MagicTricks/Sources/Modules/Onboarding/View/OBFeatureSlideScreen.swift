//
//  OBFeatureSlideScreen.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import SwiftUI

// MARK: - Feature type

enum OBFeatureType {
    case instructions
    case noProps
    case vibrations

    var title: String {
        switch self {
        case .instructions: String(localized: "onboarding.feature.instructions.title")
        case .noProps:      String(localized: "onboarding.feature.noprops.title")
        case .vibrations:   String(localized: "onboarding.feature.vibrations.title")
        }
    }

    func subtitle(for goals: Set<OnboardingGoal>) -> String {
        switch self {
        case .instructions: return String(localized: "onboarding.feature.instructions.subtitle")
        case .vibrations:   return String(localized: "onboarding.feature.vibrations.subtitle")
        case .noProps:      return noPropsSubtitle(for: goals)
        }
    }

    // Each goal combination keeps its own hand-written copy (unlike the onboarding loading phrase,
    // these aren't generic enough to synthesize from per-goal fragments) - the key is just the
    // matched goals' raw values joined by ".", built once instead of listing all 15 combinations.
    private func noPropsSubtitle(for goals: Set<OnboardingGoal>) -> String {
        if goals.contains(.everywhere) {
            return String(localized: "onboarding.feature.noprops.subtitle.everywhere")
        }
        let matched = goals.orderedCombinableGoals
        guard !matched.isEmpty else {
            return String(localized: "onboarding.feature.noprops.subtitle")
        }
        let suffix = matched.map(\.rawValue).joined(separator: ".")
        return String(localized: String.LocalizationValue("onboarding.feature.noprops.subtitle.\(suffix)"))
    }
}

// MARK: - Screen

struct OBFeatureSlideScreen: View {
    let feature: OBFeatureType
    let goals: Set<OnboardingGoal>
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            featureVisual
                .onboardingAppear(appeared, offset: 18, delay: 0.06)

            Spacer()

            VStack(spacing: 10) {
                Text(feature.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .onboardingAppear(appeared, offset: 12, delay: 0.18)

                Text(feature.subtitle(for: goals))
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .onboardingAppear(appeared, offset: 8, delay: 0.25)
            }

            Spacer().frame(height: 24)

            OnboardingCTAButton(
                title: String(localized: "onboarding.cta.continue"),
                action: onContinue
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.38), value: appeared)
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(milliseconds: 240)
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var featureVisual: some View {
        switch feature {
        case .instructions: InstructionPreviewVisual()
        case .noProps:      TricksPreviewVisual()
        case .vibrations:   VibrationsVisual()
        }
    }
}

// MARK: - Visual: Instructions

private struct InstructionPreviewVisual: View {
    var body: some View {
        Image("instruction")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
    }
}

// MARK: - Visual: Tricks Collection

private struct TricksPreviewVisual: View {
    var body: some View {
        Image("tricks")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
    }
}

// MARK: - Visual: Vibrations

private struct VibrationsVisual: View {
    var body: some View {
        Image("noprops")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
    }
}
