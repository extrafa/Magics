//
//  MagicTricksApp.swift
//  Magic Tricks
//
//  Created by Ross on 07/11/2025.
//

import SwiftUI

@main
struct MagicTricksApp: App {

    @StateObject private var flow = AppFlowCoordinator()
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var storeManager = StoreManager()
    @State private var showOnboarding = !AppPreferences.shared.hasCompletedOnboarding

    var body: some Scene {
        WindowGroup {
            ZStack {
                CollectionView()
                    .tint(.primaryText)
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
