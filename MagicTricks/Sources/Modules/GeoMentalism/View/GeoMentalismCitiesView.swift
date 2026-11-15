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
    // How far each city is tipped while it flies: thrown with a tilt, it lands straight.
    @State private var tilt: [String: Double] = [:]
    @State private var lastShuffle = Date.distantPast
    @State private var shakeGate = ShakeShuffleGate()
    @State private var feedback = UIImpactFeedbackGenerator(style: .soft)

    // The cities fly to their new places one after another, like a wave over the grid, and land with a little bounce.
    private static let settle = Animation.spring(response: 0.55, dampingFraction: 0.66)
    private static let landing = Animation.spring(response: 0.45, dampingFraction: 0.55)
    private static let waveDelay = 0.03
    private static let maxTilt = 9.0
    private static let flightBeforeLanding: TimeInterval = 0.15
    // A shuffle that is still settling does not start another one.
    private static let shuffleCooldown: TimeInterval = 0.9

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
                                .rotationEffect(.degrees(tilt[displayedCity] ?? 0))
                                .animation(
                                    reduceMotion ? nil : Self.settle.delay(Double(index) * Self.waveDelay),
                                    value: viewModel.displayedCities
                                )
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

    // The same shuffle for the button, the shake and the first moment: the cities are thrown with a tilt, fly to their places in a wave
    // and land straight with a little bounce.
    private func shuffle(withFeedback: Bool) {
        guard Date().timeIntervalSince(lastShuffle) > Self.shuffleCooldown else { return }
        lastShuffle = Date()
        guard !reduceMotion else {
            viewModel.shuffleList()
            if withFeedback { feedback.impactOccurred() }
            return
        }
        withAnimation(Self.settle) {
            viewModel.shuffleList()
            tilt = Dictionary(uniqueKeysWithValues: viewModel.displayedCities.map { ($0, Double.random(in: -Self.maxTilt...Self.maxTilt)) })
        }
        if withFeedback { feedback.impactOccurred() }
        Task {
            try? await Task.sleep(seconds: Self.flightBeforeLanding)
            withAnimation(Self.landing) { tilt = [:] }
        }
    }

    private var shuffleButton: some View {
        Button {
            shuffle(withFeedback: true)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "shuffle")
                    .font(.system(size: 17, weight: .semibold))
                    .accessibilityHidden(true)
                Text(String(localized: "geo.shuffle"))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Color.backgroundScreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.buttonPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }
}

// When a shake shuffles the cities: at once when it begins, and when it ends only if its beginning was missed. So a long shake
// shuffles once, and the cities do not wait for the shaking to stop.
struct ShakeShuffleGate {
    private var isHandled = false

    mutating func began() -> Bool {
        isHandled = true
        return true
    }

    mutating func ended() -> Bool {
        defer { isHandled = false }
        return !isHandled
    }

    mutating func cancelled() {
        isHandled = false
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
