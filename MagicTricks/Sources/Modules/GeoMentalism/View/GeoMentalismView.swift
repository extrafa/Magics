//
//  GeoMentalismView.swift
//  MagicTricks
//
//  Created by Ross on 29/07/2026.
//

import SwiftUI

struct GeoMentalismView: View {
    @State private var isExitHintVisible: Bool

    init(preferences: ExitHintPreferenceManaging = AppPreferences.shared) {
        _isExitHintVisible = State(initialValue: preferences.isExitHintEnabled)
    }

    private var statusBarHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.top ?? 59
    }

    // For the spectator who gets the phone with this list: what to do first.
    private var tapHint: some View {
        Label {
            Text(String(localized: "geo.list.hint"))
        } icon: {
            Image(systemName: "hand.tap.fill")
                .accessibilityHidden(true)
        }
        .font(.system(.subheadline, design: .rounded, weight: .semibold))
        .foregroundStyle(Color.textSecondary)
        .padding(.vertical, 4)
    }

    var body: some View {
        ZStack {
            Color.backgroundScreen.ignoresSafeArea()

            List {
                tapHint
                    .listRowBackground(Color.backgroundScreen)
                    .listRowSeparator(.hidden)

                ForEach(GeoMentalismCities.all, id: \.self) { city in
                    NavigationLink {
                        GeoMentalismCitiesView(city: city, isExitHintVisible: $isExitHintVisible)
                    } label: {
                        Text(city)
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.backgroundScreen)
                    .listRowSeparatorTint(Color.cardBorder)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            ExitHintView(isExitHintVisible: $isExitHintVisible)
                .padding(.top, statusBarHeight)
                .ignoresSafeArea(edges: .top)
        }
        .navigationTitle(String(localized: "geo.list.title"))
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        GeoMentalismView()
    }
}
