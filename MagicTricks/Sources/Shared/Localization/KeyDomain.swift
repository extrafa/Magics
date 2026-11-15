//
//  KeyDomain.swift
//  Magic Tricks
//
//  Created by Ross on 25/09/2026.
//

import Foundation

struct KeyDomain {
    private let prefix: String

    init(_ prefix: String) {
        self.prefix = prefix
    }

    func callAsFunction(_ suffix: String) -> String {
        "\(prefix).\(suffix)"
    }
}

struct L10nDomain {
    private let domain: KeyDomain

    init(_ prefix: String) {
        domain = KeyDomain(prefix)
    }

    func callAsFunction(_ suffix: String) -> LocalizedStringResource {
        LocalizedStringResource(String.LocalizationValue(stringLiteral: domain(suffix)))
    }
}
