//
//  AppBuildEnvironment.swift
//  Magic Tricks
//
//  Created by Ross on 28/08/2026.
//

import Foundation

enum AppBuildEnvironment {
    static let isSandboxOrDebug: Bool = {
        #if DEBUG
        true
        #else
        Bundle.main.appStoreReceiptURL?.path.contains("sandboxReceipt") ?? false
        #endif
    }()
}
