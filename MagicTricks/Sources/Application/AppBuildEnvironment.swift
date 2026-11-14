//
//  AppBuildEnvironment.swift
//  Magic Tricks
//
//  Created by Ross on 28/08/2026.
//

import Foundation

enum AppBuildEnvironment {
    // Not a receipt check: App Review builds carry a sandbox receipt too and would see tester-only toggles.
    static let isInternalBuild: Bool = {
        #if DEBUG || BETA
        true
        #else
        false
        #endif
    }()

    // The tester toggle that ends the onboarding without its paywall step; read by the code that obeys it.
    static let skipOnboardingPaywallKey = "dev.skipOnboardingPaywall"

    // Always off in a release build, whatever is stored.
    static var skipsOnboardingPaywall: Bool {
        isInternalBuild && UserDefaults.standard.bool(forKey: skipOnboardingPaywallKey)
    }

    // What this build was compiled as, for the tester section of the settings.
    static let configurationName: String = {
        #if DEBUG
        "Debug"
        #elseif BETA
        "Beta"
        #else
        "Release"
        #endif
    }()
}
