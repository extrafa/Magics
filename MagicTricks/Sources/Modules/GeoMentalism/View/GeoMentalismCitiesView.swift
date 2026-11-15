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
    // While the phone is shaken the cities tremble; `wobble` flips fast to drive it.
    @State private var isShaking = false
    @State private var wobble = false
    @State private var trembleTask: Task<Void, Never>?
    @State private var lastShuffle = Date.distantPast
    @State private var feedback = UIImpactFeedbackGenerator(style: .soft)

    // The cities settle into their new places one after another, like a wave over the grid.
    private static let settle = Animation.spring(response: 0.6, dampingFraction: 0.68)
    private static let waveDelay = 0.035
    // A shuffle that is still settling does not start another one.
    private static let shuffleCooldown: TimeInterval = 0.9
    private static let maxTrembleDuration: TimeInterval = 1.6

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
                                .rotationEffect(.degrees(isShaking ? tremble(at: index) : 0))
                                .animation(.linear(duration: 0.06), value: wobble)
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
        .onShake(
            began: startTrembling,
            ended: {
                trembleTask?.cancel()
                trembleTask = nil
                shuffle(withFeedback: true)
            },
            cancelled: stopTrembling
        )
        .onDisappear(perform: stopTrembling)
    }

    // The cities shake like pieces in a box: each one tips a little, the neighbours the other way.
    private func tremble(at index: Int) -> Double {
        let size = 2.2 + Double(index % 3) * 0.7
        return (index % 2 == 0) == wobble ? size : -size
    }

    private func startTrembling() {
        guard !reduceMotion, !isShaking, Date().timeIntervalSince(lastShuffle) > Self.shuffleCooldown else { return }
        feedback.prepare()
        isShaking = true
        trembleTask = Task {
            var elapsed: TimeInterval = 0
            while !Task.isCancelled, elapsed < Self.maxTrembleDuration {
                wobble.toggle()
                try? await Task.sleep(seconds: 0.07)
                elapsed += 0.07
            }
            // A shake that never reports its end still ends in a shuffle.
            guard !Task.isCancelled else { return }
            trembleTask = nil
            shuffle(withFeedback: true)
        }
    }

    private func stopTrembling() {
        trembleTask?.cancel()
        trembleTask = nil
        isShaking = false
    }

    // The same shuffle for the button, the shake and the first moment: the cities untwist and fly to their places in a wave.
    private func shuffle(withFeedback: Bool) {
        let isCoolingDown = Date().timeIntervalSince(lastShuffle) <= Self.shuffleCooldown
        // The tremble stops inside the same animation, so the cities straighten on their way instead of snapping.
        withAnimation(reduceMotion ? nil : Self.settle) {
            isShaking = false
            if !isCoolingDown { viewModel.shuffleList() }
        }
        guard !isCoolingDown else { return }
        lastShuffle = Date()
        if withFeedback { feedback.impactOccurred() }
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
