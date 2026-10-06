//
//  PaywallContentTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

final class PaywallContentTests: XCTestCase {

    private let collection = TrickCollection.tricks

    func test_rows_listEveryTrickInCollectionOrderThenTheWatermarkPerk() {
        let content = PaywallContent(context: .general)

        XCTAssertEqual(content.rows.compactMap(\.trickType), collection.map(\.id))
        XCTAssertEqual(content.rows.last?.id, "noWatermark")
        XCTAssertEqual(content.rows.count, collection.count + 1)
    }

    func test_rows_marksOnlyTheFreeTricksAsFree() {
        let content = PaywallContent(context: .general)

        for row in content.rows {
            if let type = row.trickType {
                XCTAssertEqual(row.isFree, !type.requiresPro, "\(type)")
            } else {
                XCTAssertFalse(row.isFree, "the watermark perk is Pro only")
            }
        }
    }

    func test_general_hasNoHighlight() {
        XCTAssertNil(PaywallContent(context: .general).highlighted)
    }

    func test_contextual_highlightsTheTappedTrickWithoutReorderingRows() {
        let general = PaywallContent(context: .general)

        let content = PaywallContent(context: .trick(.timeControl))

        XCTAssertEqual(content.highlighted, .timeControl)
        XCTAssertEqual(content.rows.map(\.id), general.rows.map(\.id))
    }

    func test_contextual_headlineNamesTheTappedTrick() {
        let tapped = collection.first { $0.id == .phantomDraw }!

        let content = PaywallContent(context: .trick(.phantomDraw))

        XCTAssertTrue(content.headline.contains(String(localized: tapped.title)))
    }

    func test_contextual_subtitleCountsEveryTrick() {
        let content = PaywallContent(context: .trick(.colorSense))

        XCTAssertTrue(content.subtitle.contains("\(collection.count)"))
    }

    func test_contextual_forTheFreeTrick_fallsBackToGeneral() {
        let content = PaywallContent(context: .trick(.geoMentalism))

        XCTAssertNil(content.highlighted)
        XCTAssertEqual(content.headline, PaywallContent(context: .general).headline)
    }

    func test_rowTitles_areFlatAndResolved() {
        for row in PaywallContent(context: .general).rows {
            XCTAssertFalse(row.title.contains("\n"), "\(row.id) title has a line break")
            XCTAssertFalse(row.title.hasPrefix("paywall."), "unresolved key: \(row.title)")
            XCTAssertFalse(row.title.isEmpty)
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
}
