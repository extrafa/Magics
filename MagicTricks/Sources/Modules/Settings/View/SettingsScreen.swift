//
//  SettingsScreen.swift
//  Magic Tricks
//
//  Created by Ross on 24/04/2026.
//

import SwiftUI

struct SettingsScreen: View {

    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var flow: AppFlowCoordinator

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    exitHintSection
                    vibrationsSection
                    appSection
                    aboutSection
                    HapticHelpSection()
                    if showsTestFlightSection {
                        testFlightSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }
            .hideScrollIndicators()
        }
        .navigationTitle(String(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .storeErrorAlert(storeManager)
    }
}

private extension SettingsScreen {

    var showsTestFlightSection: Bool {
        AppBuildEnvironment.isSandboxOrDebug
    }

    var testFlightSection: some View {
        SettingsSection(title: "TestFlight") {
            VStack(spacing: 0) {
                Toggle(isOn: $storeManager.isProOverride) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "settings.proOverride.title"))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.primaryText)

                        Text(String(localized: "settings.proOverride.description"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primaryText.opacity(0.58))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(.orange)
                .padding(18)

                SettingsDivider()

                Button {
                    AppPreferences.shared.hasRespondedToRating = false
                    AppPreferences.shared.trickLaunchCount = 0
                    flow.activeSheet = .rateApp
                } label: {
                    SettingsActionRow(icon: "star.bubble", title: String(localized: "settings.showRateAppSheet"))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)

                SettingsDivider()

                Toggle(isOn: $storeManager.isWatermarkHidden) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "settings.hideWatermark.title"))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.primaryText)

                        Text(String(localized: "settings.hideWatermark.description"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primaryText.opacity(0.58))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(.orange)
                .padding(18)
            }
            .cardSurface(cornerRadius: 20)
        }
    }

    var exitHintSection: some View {
        SettingsSection(title: String(localized: "settings.exitHint.section")) {
            Toggle(isOn: $store.isExitHintEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "settings.exitHint"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)

                    Text(String(localized: "settings.exitHint.description"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.primaryText.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(TrickPalette.Collection.timeControl)
            .padding(18)
            .cardSurface(cornerRadius: 20)
        }
    }

    var vibrationsSection: some View {
        SettingsSection(title: String(localized: "settings.section.vibrations")) {
            VStack(spacing: 0) {
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

                SettingsDivider()

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
            }
            .padding(.horizontal, 18)
            .cardSurface(cornerRadius: 20)
        }
    }

    @ViewBuilder
    var appSection: some View {
        if let appShareURL = store.appShareURL {
            SettingsSection(title: String(localized: "settings.section.app")) {
                VStack(spacing: 0) {
                    shareButton(url: appShareURL)
                }
                .padding(.horizontal, 18)
                .cardSurface(cornerRadius: 20)
            }
        }
    }

    func shareButton(url: URL) -> some View {
        ShareLink(item: url, subject: Text(store.appShareText)) {
            SettingsActionRow(
                icon: "square.and.arrow.up",
                title: String(localized: "settings.shareApp")
            )
        }
    }

    var aboutSection: some View {
        SettingsSection(title: String(localized: "settings.section.about")) {
            VStack(spacing: 0) {
                Link(destination: AppConfig.privacyPolicyURL) {
                    SettingsActionRow(
                        icon: "hand.raised",
                        title: String(localized: "settings.privacyPolicy"),
                        showsChevron: true
                    )
                }

                SettingsDivider()

                Link(destination: AppConfig.termsOfUseURL) {
                    SettingsActionRow(
                        icon: "doc.text",
                        title: String(localized: "settings.termsOfUse"),
                        showsChevron: true
                    )
                }

                if let supportURL = AppConfig.supportMailURL(subject: "Magic Tricks Support") {
                    SettingsDivider()

                    Link(destination: supportURL) {
                        SettingsActionRow(
                            icon: "envelope",
                            title: String(localized: "settings.contactSupport"),
                            showsChevron: true
                        )
                    }
                }

                SettingsDivider()

                restoreButton
            }
            .padding(.horizontal, 18)
            .cardSurface(cornerRadius: 20)
        }
    }

    var restoreButton: some View {
        Button {
            Task { await storeManager.restore() }
        } label: {
            if storeManager.phase == .restoring {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 58)
            } else {
                SettingsActionRow(icon: "arrow.clockwise", title: String(localized: "settings.restorePurchases"))
            }
        }
        .buttonStyle(.plain)
        .disabled(storeManager.phase != .idle)
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
            .environmentObject(SettingsStore())
            .environmentObject(StoreManager())
    }
}
