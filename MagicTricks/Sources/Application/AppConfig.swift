//
//  AppConfig.swift
//  Magic Tricks
//
//  Created by Ross on 01/03/2026.
//

import Foundation

enum AppConfig {
    static let appStoreURL: URL? = nil
    static let privacyPolicyURL = URL(string: "https://extrafa.github.io/Magics/privacy-policy")!
    static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let supportEmail = "usmoder@gmail.com"

    static func supportMailURL(subject: String) -> URL? {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:\(supportEmail)?subject=\(encodedSubject)")
    }
}
