//
//  PaywallContentTests.swift
//  MagicTricksTests
//

import SwiftUI
import XCTest
@testable import MagicTricks

final class PaywallContentTests: XCTestCase {

    private let collection = TrickCollection.tricks

    func test_cards_areTheProTricksInCollectionOrder() {
        let content = PaywallContent(context: .general)

        XCTAssertEqual(content.cards.map(\.id), collection.filter { $0.id.requiresPro }.map(\.id))
        XCTAssertFalse(content.cards.contains { !$0.id.requiresPro }, "the free trick is not a card")
    }

    func test_contextual_putsTheTappedTrickOnTopOfTheFanKeepingTheRest() {
        let general = PaywallContent(context: .general)

        let content = PaywallContent(context: .trick(.timeControl))

        XCTAssertEqual(content.cards.last?.id, .timeControl)
        XCTAssertEqual(Set(content.cards.map(\.id)), Set(general.cards.map(\.id)))
        XCTAssertEqual(content.cards.count, general.cards.count)
        XCTAssertEqual(content.cards.dropLast().map(\.id), general.cards.map(\.id).filter { $0 != .timeControl })
    }

    func test_contextual_headlineNamesTheTappedTrick() {
        let tapped = collection.first { $0.id == .phantomDraw }!

        let content = PaywallContent(context: .trick(.phantomDraw))

        XCTAssertTrue(content.headline.contains(String(localized: tapped.title)))
    }

    func test_contextual_forTheFreeTrick_fallsBackToGeneral() {
        let content = PaywallContent(context: .trick(.geoMentalism))

        XCTAssertNil(content.focus)
        XCTAssertEqual(content.cards.map(\.id), PaywallContent(context: .general).cards.map(\.id))
        XCTAssertEqual(content.headline, PaywallContent(context: .general).headline)
    }

    func test_copy_isResolvedNotRawKeys() {
        let general = PaywallContent(context: .general)
        let contextual = PaywallContent(context: .trick(.colorSense))

        for text in [general.headline, contextual.headline] {
            XCTAssertFalse(text.hasPrefix("paywall."), "unresolved key: \(text)")
            XCTAssertFalse(text.isEmpty)
        }
    }

    func test_general_hasNoFocusAndNoEffect() {
        let content = PaywallContent(context: .general)

        XCTAssertNil(content.focus)
        XCTAssertNil(content.effect)
    }

    func test_rows_areFreeThenPayThenWatermark() {
        let content = PaywallContent(context: .general)

        XCTAssertEqual(content.rows.map(\.symbol), ["checkmark.circle.fill", "lock.open.fill", "sparkles"])
        XCTAssertEqual(Set(content.rows.map(\.title)).count, 3, "the titles identify the rows")
    }

    func test_rows_freeAndWatermarkNameOnlyTheFreeTrick_payNamesEveryProTrick() {
        let rows = PaywallContent(context: .general).rows
        let free = rows[0].text, pay = rows[1].text, watermark = rows[2].text

        for trick in collection {
            let name = String(localized: trick.title)
            XCTAssertEqual(free.contains(name), !trick.id.requiresPro, "free row: \(name)")
            XCTAssertEqual(pay.contains(name), trick.id.requiresPro, "pay row: \(name)")
            XCTAssertEqual(watermark.contains(name), !trick.id.requiresPro, "watermark row: \(name)")
        }
    }

    func test_contextual_hasTheSameRowsAsGeneral() {
        XCTAssertEqual(PaywallContent(context: .trick(.timeControl)).rows, PaywallContent(context: .general).rows)
    }

    func test_rows_areResolvedNotRawKeys() {
        for row in PaywallContent(context: .general).rows {
            XCTAssertFalse(row.title.hasPrefix("paywall."), row.title)
            XCTAssertFalse(row.text.hasPrefix("paywall."), row.text)
            XCTAssertFalse(row.text.contains("%@"), row.text)
        }
    }

    func test_contextual_focusesTheTappedTrickAndDescribesIt() throws {
        let tapped = collection.first { $0.id == .phantomDraw }!

        let content = PaywallContent(context: .trick(.phantomDraw))

        XCTAssertEqual(content.focus?.id, .phantomDraw)
        XCTAssertEqual(content.effect, String(localized: tapped.subtitle))
    }

    func test_withNoFreeTrick_hasOnlyThePayRow() {
        let onlyPro = collection.filter { $0.id.requiresPro }

        let content = PaywallContent(context: .general, tricks: onlyPro)

        XCTAssertEqual(content.rows.map(\.symbol), ["lock.open.fill"])
    }

    func test_withNoProTrick_hasNoPayRow() {
        let onlyFree = collection.filter { !$0.id.requiresPro }

        let content = PaywallContent(context: .general, tricks: onlyFree)

        XCTAssertFalse(content.rows.map(\.symbol).contains("lock.open.fill"))
    }

    func test_count_isTheProTricksNeverTheWholeCollection() {
        let pro = collection.filter { $0.id.requiresPro }.count
        XCTAssertNotEqual(pro, collection.count)

        let general = PaywallContent(context: .general).headline

        XCTAssertTrue(general.contains("\(pro)"), general)
        XCTAssertFalse(general.contains("\(collection.count)"), general)
    }

    func test_general_withASingleProTrick_usesTheSingularHeadline() {
        let freeAndOnePro = collection.filter { !$0.id.requiresPro || $0.id == .phantomDraw }
        let key = L10nDomain("paywall")

        let content = PaywallContent(context: .general, tricks: freeAndOnePro)

        XCTAssertEqual(content.headline, String.localizedStringWithFormat(String(localized: key("title.one")), 1))
    }
}

final class TrickTextColorContrastTests: XCTestCase {

    func test_trickNameColors_keepAtLeast4point5ToOneOnTheScreenBackground_inBothThemes() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let background = UIColor(Color.backgroundScreen).resolvedColor(with: traits)

            for trick in TrickType.allCases {
                let text = UIColor(trick.textColor).resolvedColor(with: traits)

                XCTAssertGreaterThanOrEqual(
                    Self.contrastRatio(text, background), 4.5,
                    "\(trick) in \(style == .dark ? "dark" : "light") theme"
                )
            }
        }
    }

    private static func luminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        func linear(_ c: CGFloat) -> Double {
            let v = Double(c)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    private static func contrastRatio(_ a: UIColor, _ b: UIColor) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }
}
