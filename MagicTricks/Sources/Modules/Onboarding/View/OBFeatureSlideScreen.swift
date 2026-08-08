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

    func subtitle(for goal: OnboardingGoal?) -> String {
        switch self {
        case .instructions: String(localized: "onboarding.feature.instructions.subtitle")
        case .vibrations:   String(localized: "onboarding.feature.vibrations.subtitle")
        case .noProps:
            switch goal {
            case .parties:    String(localized: "onboarding.feature.noprops.subtitle.parties")
            case .dates:      String(localized: "onboarding.feature.noprops.subtitle.dates")
            case .work:       String(localized: "onboarding.feature.noprops.subtitle.work")
            case .family:     String(localized: "onboarding.feature.noprops.subtitle.family")
            case .everywhere: String(localized: "onboarding.feature.noprops.subtitle.everywhere")
            case nil:         String(localized: "onboarding.feature.noprops.subtitle")
            }
        }
    }
}

// MARK: - Screen

struct OBFeatureSlideScreen: View {
    let feature: OBFeatureType
    let goal: OnboardingGoal?
    let pageIndex: Int
    let onContinue: () -> Void

    @State private var appeared = false

    private let totalPages = 3

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

                Text(feature.subtitle(for: goal))
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.25), value: appeared)
            }

            pageDots
                .padding(.top, 28)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.32), value: appeared)

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
                try? await Task.sleep(for: .milliseconds(240))
                appeared = true
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == pageIndex ? Color.primaryText : Color.primaryText.opacity(0.2))
                    .frame(width: i == pageIndex ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: pageIndex)
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
