//
//  PaywallContentTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

final class PaywallContentTests: XCTestCase {

    private let proTypes = TrickCollection.tricks.filter { $0.id.requiresPro }.map(\.id)

    func test_general_listsEveryProTrickInCollectionOrderWithNoHighlight() {
        let content = PaywallContent(context: .general)

        XCTAssertNil(content.highlighted)
        XCTAssertEqual(content.tricks.map(\.id), proTypes)
    }

    func test_general_neverIncludesTheFreeTrick() {
        let content = PaywallContent(context: .general)

        XCTAssertFalse(content.tricks.contains { !$0.id.requiresPro })
    }

    func test_contextual_putsTheTappedTrickFirstAndKeepsTheRestInOrder() {
        let tapped = TrickType.timeControl

        let content = PaywallContent(context: .trick(tapped))

        XCTAssertEqual(content.highlighted?.id, tapped)
        XCTAssertEqual(content.tricks.first?.id, tapped)
        XCTAssertEqual(content.others.map(\.id), proTypes.filter { $0 != tapped })
        XCTAssertEqual(content.tricks.count, proTypes.count)
    }

    func test_contextual_headlineNamesTheTappedTrick() {
        let tapped = TrickCollection.tricks.first { $0.id == .phantomDraw }!

        let content = PaywallContent(context: .trick(.phantomDraw))

        XCTAssertTrue(content.headline.contains(String(localized: tapped.title)))
    }

    func test_contextual_forTheFreeTrick_fallsBackToGeneral() {
        let content = PaywallContent(context: .trick(.geoMentalism))

        XCTAssertNil(content.highlighted)
        XCTAssertEqual(content.tricks.map(\.id), proTypes)
    }

    func test_everyProTrick_hasAResolvedEffectLine() {
        for type in proTypes {
            let effect = type.paywallEffect

            XCTAssertNotNil(effect, "\(type) has no paywall effect")
            XCTAssertFalse(effect?.hasPrefix("paywall.") ?? true, "\(type) effect is an unresolved key: \(effect ?? "")")
        }
    }

    func test_copy_isResolvedNotRawKeys() {
        let general = PaywallContent(context: .general)
        let contextual = PaywallContent(context: .trick(.colorSense))

        for text in [general.headline, general.subtitle, contextual.headline, contextual.subtitle] {
            XCTAssertFalse(text.hasPrefix("paywall."), "unresolved key: \(text)")
            XCTAssertFalse(text.isEmpty)
        }
    }

    func test_subtitle_countsFromTheFreeTricksToAllOfThem() {
        let general = PaywallContent(context: .general)
        let contextual = PaywallContent(context: .trick(.colorSense))

        let freeCount = TrickCollection.tricks.filter { !$0.id.requiresPro }.count
        XCTAssertTrue(general.subtitle.contains("\(freeCount + proTypes.count)"))
        XCTAssertTrue(contextual.subtitle.contains("\(proTypes.count - 1)"))
    }
}
