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
private let hideHapticsNoticeKey = L10nDomain("settings.hideHapticsNotice")
private let restartOnboardingKey = L10nDomain("settings.restartOnboarding")
private let skipOnboardingPaywallKey = L10nDomain("settings.skipOnboardingPaywall")
private let exitHintKey = L10nDomain("settings.exitHint")
private let paywallKey = L10nDomain("paywall")

struct SettingsScreen: View {

    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var flow: AppFlowCoordinator
    @State private var storeAlert: StoreAlert?
    @State private var isRestartOnboardingConfirmPresented = false
    @AppStorage(AppBuildEnvironment.skipOnboardingPaywallKey) private var skipsOnboardingPaywall = false
    @AppStorage(HapticsUnavailableNotice.testerHiddenKey) private var isHapticsNoticeHidden = false

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
        .storeErrorAlert($storeAlert)
        .alert(
            String(localized: restartOnboardingKey("title")),
            isPresented: $isRestartOnboardingConfirmPresented
        ) {
            Button(String(localized: restartOnboardingKey("confirm")), role: .destructive) {
                flow.restartOnboarding()
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: restartOnboardingKey("message")))
        }
    }
}

private extension SettingsScreen {

    var showsTestFlightSection: Bool {
        AppBuildEnvironment.isInternalBuild
    }

    // Which build this is and what the store says, so a call can start with "this is the build I mean".
    var buildInfo: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        let access = storeManager.showsFreeTier ? "Free" : "Pro"
        return "\(version) (\(build)) · \(AppBuildEnvironment.configurationName)\n\(Bundle.main.bundleIdentifier ?? "?")\nAccess: \(access)"
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

                Button {
                    isRestartOnboardingConfirmPresented = true
                } label: {
                    SettingsActionRow(icon: "arrow.counterclockwise", title: String(localized: restartOnboardingKey("title")))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)

                SettingsDivider()

                SettingsToggleRow(
                    title: String(localized: skipOnboardingPaywallKey("title")),
                    subtitle: String(localized: skipOnboardingPaywallKey("description")),
                    tint: .orange,
                    isOn: $skipsOnboardingPaywall
                )

                SettingsDivider()

                Button {
                    flow.openPaywall()
                } label: {
                    SettingsActionRow(icon: "creditcard", title: String(localized: "settings.showPaywall"))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                // With Pro the paywall closes itself the moment it opens, so the row waits until the override is off.
                .disabled(storeManager.hasProAccess)
                .opacity(storeManager.hasProAccess ? 0.4 : 1)

                if storeManager.hasProAccess {
                    Text(String(localized: "settings.showPaywall.disabledHint"))
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 10)
                }

                SettingsDivider()

                SettingsToggleRow(
                    title: String(localized: hideWatermarkKey("title")),
                    subtitle: String(localized: hideWatermarkKey("description")),
                    tint: .orange,
                    isOn: $storeManager.isWatermarkHidden
                )

                SettingsDivider()

                SettingsToggleRow(
                    title: String(localized: hideHapticsNoticeKey("title")),
                    subtitle: String(localized: hideHapticsNoticeKey("description")),
                    tint: .orange,
                    isOn: $isHapticsNoticeHidden
                )

                SettingsDivider()

                Text(buildInfo)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .textSelection(.enabled)
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
            Task { storeAlert = await storeManager.restore() }
        } label: {
            if storeManager.isRestoring {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(minHeight: 58)
            } else {
                SettingsActionRow(icon: "arrow.clockwise", title: String(localized: paywallKey("restore")))
            }
        }
        .buttonStyle(.plain)
        .disabled(storeManager.isTransacting)
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
            .environmentObject(SettingsStore())
            .environmentObject(StoreManager())
    }
}
