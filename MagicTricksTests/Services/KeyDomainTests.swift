//
//  KeyDomainTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

final class KeyDomainTests: XCTestCase {

    func test_keyDomain_joinsPrefixAndSuffixWithDot() {
        let key = KeyDomain("some.domain")

        XCTAssertEqual(key("example"), "some.domain.example")
    }

    func test_l10nDomain_resolvesToLocalizedStringResourceWithJoinedKey() {
        let key = L10nDomain("some.domain")

        let resource = key("example")

        XCTAssertEqual(String(localized: resource), String(localized: "some.domain.example"))
    }
}
