//
//  GeoMentalismCitiesView.swift
//  MagicTricks
//
//  Created by Ross on 29/07/2026.
//

import SwiftUI

struct GeoMentalismCitiesView: View {
    @StateObject private var viewModel: GeoMentalismViewModel
    let city: String
    @Binding var isExitHintVisible: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var flight = ShuffleFlight<String>()
    @State private var shakeGate = ShakeShuffleGate()
    @State private var feedback = UIImpactFeedbackGenerator(style: .soft)

    private static let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    init(city: String, isExitHintVisible: Binding<Bool>, viewModel: GeoMentalismViewModel? = nil) {
        self.city = city
        _isExitHintVisible = isExitHintVisible
        _viewModel = StateObject(wrappedValue: viewModel ?? GeoMentalismViewModel())
    }

    var body: some View {
        ZStack {
            Color.backgroundScreen.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    ReadAloudReminder(citiesCount: GeoMentalismViewModel.listSize)

                    LazyVGrid(columns: Self.columns, spacing: 12) {
                        ForEach(Array(viewModel.displayedCities.enumerated()), id: \.element) { index, displayedCity in
                            CityCapsule(city: displayedCity)
                                .rotationEffect(.degrees(flight.tilt[displayedCity] ?? 0))
                                .animation(reduceMotion ? nil : ShuffleFlight<String>.wave(at: index), value: viewModel.displayedCities)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .scrollBouncesOnlyWhenNeeded()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            shuffleButton
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Kept on the spectator's screen on purpose: it marks the free tier and Pro removes it (monetisation decision).
                WatermarkView()
            }
        }
        .onAppear {
            isExitHintVisible = false
            viewModel.generateList(for: city)
        }
        .task {
            try? await Task.sleep(milliseconds: 550)
            shuffle(withFeedback: false)
        }
        // The shuffle starts when the system recognises the shake, not when the shaking stops.
        .onShake(
            began: {
                if shakeGate.began() { shuffle(withFeedback: true) }
            },
            ended: {
                if shakeGate.ended() { shuffle(withFeedback: true) }
            },
            cancelled: { shakeGate.cancelled() }
        )
        .onAppear { feedback.prepare() }
    }

    // The same shuffle for the button, the shake and the first moment.
    private func shuffle(withFeedback: Bool) {
        let didShuffle = flight.run(
            reduceMotion: reduceMotion,
            reorder: viewModel.shuffleList,
            ids: { viewModel.displayedCities }
        )
        if didShuffle && withFeedback { feedback.impactOccurred() }
    }

    private var shuffleButton: some View {
        ShuffleButton { shuffle(withFeedback: true) }
    }
}

// The reminder the spectator sees above the list: what to do now, in two short lines.
private struct ReadAloudReminder: View {
    let citiesCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    private var tint: Color { TrickType.geoMentalism.collectionColor }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(Circle().fill(tint.opacity(0.16)))
                .speakingPulse(isActive: !reduceMotion)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "geo.reminder.title"))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(String.localizedStringWithFormat(String(localized: "geo.reminder.subtitle"), citiesCount))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .cardSurface(cornerRadius: 20)
        .accessibilityElement(children: .combine)
        // It comes in right after the list, so the eye first lands on the cities and then on what to do.
        .opacity(isShown ? 1 : 0)
        .offset(y: isShown || reduceMotion ? 0 : -8)
        .task {
            try? await Task.sleep(milliseconds: 250)
            withAnimation(.easeOut(duration: 0.35)) { isShown = true }
        }
    }
}

private extension View {
    // The waves of the speaker keep moving, like someone talking (iOS 17 and later).
    @ViewBuilder
    func speakingPulse(isActive: Bool) -> some View {
        if #available(iOS 17.0, *) {
            symbolEffect(.variableColor.iterative.reversing, options: .repeating, isActive: isActive)
        } else {
            self
        }
    }
}

#Preview {
    struct Preview: View {
        @State var isExitHintVisible = false
        var body: some View {
            NavigationStack {
                GeoMentalismCitiesView(city: "Barcelona", isExitHintVisible: $isExitHintVisible)
            }
            .environmentObject(StoreManager())
        }
    }
    return Preview()
}
