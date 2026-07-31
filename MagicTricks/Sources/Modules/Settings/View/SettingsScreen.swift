//
//  SettingsScreen.swift
//  Magic Tricks
//
//  Created by Ross on 24/04/2026.
//

import SwiftUI
import StoreKit

struct SettingsScreen: View {

    @EnvironmentObject private var store: SettingsStore
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    vibrationsSection
                    appSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(String(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .fontDesign(.rounded)
    }
}

private extension SettingsScreen {

    var vibrationsSection: some View {
        SettingsSection(title: String(localized: "settings.section.vibrations")) {
            VStack(spacing: 0) {
                NavigationLink {
                    HapticTrainingView()
                } label: {
                    SettingsActionRow(
                        icon: "dot.radiowaves.left.and.right",
                        title: String(localized: "settings.vibrationTrainer"),
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)

                SettingsDivider()

                NavigationLink {
                    HapticSettingsScreen()
                } label: {
                    SettingsActionRow(
                        icon: "waveform.path.ecg",
                        title: String(localized: "settings.vibrationSettings"),
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .settingsCard()
        }
    }

    var appSection: some View {
        SettingsSection(title: String(localized: "settings.section.app")) {
            VStack(spacing: 0) {
                shareButton
                SettingsDivider()
                Button { requestReview() } label: {
                    SettingsActionRow(
                        icon: "star",
                        title: String(localized: "settings.rateUs")
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .settingsCard()
        }
    }

    @ViewBuilder
    var shareButton: some View {
        let label = SettingsActionRow(
            icon: "square.and.arrow.up",
            title: String(localized: "settings.shareApp")
        )
        if let url = store.appShareURL {
            ShareLink(item: url) { label }.buttonStyle(.plain)
        } else {
            ShareLink(item: store.appShareText) { label }.buttonStyle(.plain)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
            .environmentObject(SettingsStore())
    }
}
