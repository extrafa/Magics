//
//  PaywallContentTests.swift
//  MagicTricksTests
//

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

    func test_general_unlocksNamesEveryProTrickAndNoFreeOne() throws {
        let content = PaywallContent(context: .general)
        let unlocks = try XCTUnwrap(content.unlocks)

        for trick in collection {
            let name = String(localized: trick.title)
            XCTAssertEqual(unlocks.contains(name), trick.id.requiresPro, name)
        }
        XCTAssertNil(content.focus)
        XCTAssertNil(content.effect)
    }

    func test_general_freeNoteNamesTheFreeTrick() throws {
        let freeNote = try XCTUnwrap(PaywallContent(context: .general).freeNote)

        for trick in collection {
            XCTAssertEqual(freeNote.contains(String(localized: trick.title)), !trick.id.requiresPro)
        }
    }

    func test_contextual_focusesTheTappedTrickAndDescribesIt() throws {
        let tapped = collection.first { $0.id == .phantomDraw }!

        let content = PaywallContent(context: .trick(.phantomDraw))

        XCTAssertEqual(content.focus?.id, .phantomDraw)
        XCTAssertEqual(content.effect, String(localized: tapped.subtitle))
    }

    func test_contextual_unlocksListsOnlyTheOtherProTricks() throws {
        let content = PaywallContent(context: .trick(.timeControl))
        let unlocks = try XCTUnwrap(content.unlocks)

        for trick in collection {
            let expected = trick.id.requiresPro && trick.id != .timeControl
            XCTAssertEqual(unlocks.contains(String(localized: trick.title)), expected, "\(trick.id)")
        }
    }

    func test_contextual_withNoOtherProTricks_hasNoUnlocksLine() {
        let onlyOnePro = collection.filter { !$0.id.requiresPro || $0.id == .phantomDraw }

        let content = PaywallContent(context: .trick(.phantomDraw), tricks: onlyOnePro)

        XCTAssertNil(content.unlocks)
    }

    func test_unlocks_countsOnlyTheProTricksNeverTheWholeCollection() throws {
        let pro = collection.filter { $0.id.requiresPro }.count
        XCTAssertNotEqual(pro, collection.count)

        let general = try XCTUnwrap(PaywallContent(context: .general).unlocks)
        let contextual = try XCTUnwrap(PaywallContent(context: .trick(.colorSense)).unlocks)

        XCTAssertTrue(general.contains("\(pro)"), general)
        XCTAssertFalse(general.contains("\(collection.count)"), general)
        XCTAssertTrue(contextual.contains("\(pro - 1)"), contextual)
        XCTAssertFalse(contextual.contains("\(collection.count)"), contextual)
    }

    func test_unlocks_withASingleProTrick_usesTheSingularSentence() throws {
        let freeAndOnePro = collection.filter { !$0.id.requiresPro || $0.id == .phantomDraw }
        let key = L10nDomain("paywall")
        let name = String(localized: collection.first { $0.id == .phantomDraw }!.title)

        let single = PaywallContent(context: .general, tricks: freeAndOnePro).unlocks

        XCTAssertEqual(single, String.localizedStringWithFormat(String(localized: key("unlocks.one")), 1, name))
    }
}
