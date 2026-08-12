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

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    exitHintSection
                    vibrationsSection
                    appSection
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
        .fontDesign(.rounded)
    }
}

private extension SettingsScreen {

    var showsTestFlightSection: Bool {
        #if DEBUG
        true
        #else
        Bundle.main.appStoreReceiptURL?.path.contains("sandboxReceipt") ?? false
        #endif
    }

    var testFlightSection: some View {
        SettingsSection(title: "TestFlight") {
            VStack(spacing: 0) {
                Toggle(isOn: $storeManager.isProOverride) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pro Access Override")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.primaryText)

                        Text("Unlocks all tricks.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primaryText.opacity(0.58))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(.orange)
                .padding(18)

                SettingsDivider()

                Toggle(isOn: $storeManager.isWatermarkHidden) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hide Watermark")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.primaryText)

                        Text("Hides the free trial banner.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primaryText.opacity(0.58))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(.orange)
                .padding(18)
            }
            .settingsCard()
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
            .settingsCard()
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
            .settingsCard()
        }
    }

    var appSection: some View {
        SettingsSection(title: String(localized: "settings.section.app")) {
            VStack(spacing: 0) {
                shareButton
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
            .environmentObject(StoreManager())
    }
}
