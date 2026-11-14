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
                        ForEach(viewModel.displayedCities, id: \.self) { displayedCity in
                            CityCapsule(city: displayedCity)
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
            withAnimation(.easeInOut) {
                viewModel.shuffleList()
            }
        }
    }

    private var shuffleButton: some View {
        Button {
            withAnimation(.easeInOut) {
                viewModel.shuffleList()
            }
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
