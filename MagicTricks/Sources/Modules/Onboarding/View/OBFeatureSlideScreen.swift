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

    private func noPropsSubtitle(for goals: Set<OnboardingGoal>) -> String {
        if goals.contains(.everywhere) { return String(localized: "onboarding.feature.noprops.subtitle.everywhere") }
        if goals == Set([.parties])                              { return String(localized: "onboarding.feature.noprops.subtitle.parties") }
        if goals == Set([.dates])                                { return String(localized: "onboarding.feature.noprops.subtitle.dates") }
        if goals == Set([.work])                                 { return String(localized: "onboarding.feature.noprops.subtitle.work") }
        if goals == Set([.family])                               { return String(localized: "onboarding.feature.noprops.subtitle.family") }
        if goals == Set([.parties, .dates])                      { return String(localized: "onboarding.feature.noprops.subtitle.parties.dates") }
        if goals == Set([.parties, .work])                       { return String(localized: "onboarding.feature.noprops.subtitle.parties.work") }
        if goals == Set([.parties, .family])                     { return String(localized: "onboarding.feature.noprops.subtitle.parties.family") }
        if goals == Set([.dates, .work])                         { return String(localized: "onboarding.feature.noprops.subtitle.dates.work") }
        if goals == Set([.dates, .family])                       { return String(localized: "onboarding.feature.noprops.subtitle.dates.family") }
        if goals == Set([.work, .family])                        { return String(localized: "onboarding.feature.noprops.subtitle.work.family") }
        if goals == Set([.parties, .dates, .work])               { return String(localized: "onboarding.feature.noprops.subtitle.parties.dates.work") }
        if goals == Set([.parties, .dates, .family])             { return String(localized: "onboarding.feature.noprops.subtitle.parties.dates.family") }
        if goals == Set([.parties, .work, .family])              { return String(localized: "onboarding.feature.noprops.subtitle.parties.work.family") }
        if goals == Set([.dates, .work, .family])                { return String(localized: "onboarding.feature.noprops.subtitle.dates.work.family") }
        return String(localized: "onboarding.feature.noprops.subtitle")
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
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
                .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.06), value: appeared)

            Spacer()

            VStack(spacing: 10) {
                Text(feature.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.18), value: appeared)

                Text(feature.subtitle(for: goals))
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.25), value: appeared)
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
