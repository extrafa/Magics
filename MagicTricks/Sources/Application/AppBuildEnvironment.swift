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
}
