//
//  SettingsScreen.swift
//  Magic Tricks
//
//  Created by Ross on 24/04/2026.
//

import SwiftUI

private let sectionKey = L10nDomain("settings.section")
private let proOverrideKey = L10nDomain("settings.proOverride")
private let hideWatermarkKey = L10nDomain("settings.hideWatermark")
private let exitHintKey = L10nDomain("settings.exitHint")
private let paywallKey = L10nDomain("onboarding.paywall")

struct SettingsScreen: View {

    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var flow: AppFlowCoordinator

    var body: some View {
        ZStack {
            Color.backgroundScreen
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
            .scrollIndicators(.hidden)
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
                SettingsToggleRow(
                    title: String(localized: proOverrideKey("title")),
                    subtitle: String(localized: proOverrideKey("description")),
                    tint: .orange,
                    isOn: $storeManager.isProOverride
                )

                SettingsDivider()

                Button {
                    flow.resetRatingState()
                    flow.activeSheet = .rateApp
                } label: {
                    SettingsActionRow(icon: "star.bubble", title: String(localized: "settings.showRateAppSheet"))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)

                SettingsDivider()

                SettingsToggleRow(
                    title: String(localized: hideWatermarkKey("title")),
                    subtitle: String(localized: hideWatermarkKey("description")),
                    tint: .orange,
                    isOn: $storeManager.isWatermarkHidden
                )
            }
            .cardSurface(cornerRadius: 20)
        }
    }

    var exitHintSection: some View {
        SettingsSection(title: String(localized: exitHintKey("section"))) {
            SettingsToggleRow(
                title: String(localized: "settings.exitHint"),
                subtitle: String(localized: exitHintKey("description")),
                isOn: $store.isExitHintEnabled
            )
            .cardSurface(cornerRadius: 20)
        }
    }

    var vibrationsSection: some View {
        SettingsSection(title: String(localized: sectionKey("vibrations"))) {
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
            SettingsSection(title: String(localized: sectionKey("app"))) {
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
        SettingsSection(title: String(localized: sectionKey("about"))) {
            VStack(spacing: 0) {
                Link(destination: AppConfig.privacyPolicyURL) {
                    SettingsActionRow(
                        icon: "hand.raised",
                        // Same key as the paywall's link - one canonical translation for the same label.
                        title: String(localized: paywallKey("privacy")),
                        showsChevron: true
                    )
                }

                SettingsDivider()

                Link(destination: AppConfig.termsOfUseURL) {
                    SettingsActionRow(
                        icon: "doc.text",
                        title: String(localized: paywallKey("terms")),
                        showsChevron: true
                    )
                }

                if let supportURL = AppConfig.supportMailURL(subject: String(localized: "settings.support.emailSubject")) {
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
