//
//  MagicTricksApp.swift
//  Magic Tricks
//
//  Created by Ross on 07/11/2025.
//

import SwiftUI

@main
struct MagicTricksApp: App {

    @StateObject private var flow: AppFlowCoordinator
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var storeManager: StoreManager
    @State private var showOnboarding = !AppPreferences.shared.hasCompletedOnboarding

    init() {
        let storeManager = StoreManager()
        _storeManager = StateObject(wrappedValue: storeManager)
        _flow = StateObject(wrappedValue: AppFlowCoordinator(store: storeManager))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                CollectionView()
                    .tint(.textPrimary)
                    .environmentObject(flow)
                    .environmentObject(settingsStore)
                    .environmentObject(storeManager)

                if showOnboarding {
                    OnboardingFlowView {
                        showOnboarding = false
                    }
                    .environmentObject(storeManager)
                    .transition(.opacity)
                }
            }
            .task { storeManager.start() }
        }
    }
}
