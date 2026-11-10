//
//  PaywallContent.swift
//  Magic Tricks
//

import Foundation

private let key = L10nDomain("paywall")

// What the paywall says and which cards it deals: the one place to tune copy.
// Cards come straight from TrickCollection, so a new Pro trick shows up on the paywall by itself.
struct PaywallContent {
    // One line of the deal: what is free, what one payment opens, what else it changes.
    struct Row: Equatable {
        let symbol: String
        let title: String
        let text: String
    }

    let headline: String
    // The Pro tricks in collection order; the tapped one goes last, so it lies on top of the fan.
    let cards: [Trick]

    // The tapped Pro trick (contextual paywall) and what it does; nil on the general paywall.
    let focus: Trick?
    let effect: String?
    // Free now, one payment, no watermark. The names come from the catalog (never typed into copy),
    // so they can't drift from what the purchase opens.
    let rows: [Row]

    init(context: PaywallContext, tricks: [Trick] = TrickCollection.tricks) {
        let proTricks = tricks.filter { $0.id.requiresPro }
        let freeTricks = tricks.filter { !$0.id.requiresPro }
        let picked: Trick?
        if case .trick(let type) = context {
            picked = proTricks.first { $0.id == type }
        } else {
            picked = nil
        }

        focus = picked
        cards = proTricks.filter { $0.id != picked?.id } + (picked.map { [$0] } ?? [])
        rows = Self.rows(free: freeTricks, pro: proTricks)

        if let picked {
            headline = String.localizedStringWithFormat(String(localized: key("contextTitle")), String(localized: picked.title))
            effect = String(localized: picked.subtitle)
        } else {
            headline = Self.countedText(key: "title", count: proTricks.count)
            effect = nil
        }
    }

    private static func rows(free: [Trick], pro: [Trick]) -> [Row] {
        var rows: [Row] = []
        if let freeNames = names(of: free) {
            rows.append(Row(
                symbol: "checkmark.circle.fill",
                title: String(localized: key("row.free.title")),
                text: String.localizedStringWithFormat(String(localized: key("row.free.text")), freeNames)
            ))
        }
        if let proNames = names(of: pro) {
            rows.append(Row(
                symbol: "lock.open.fill",
                title: String(localized: key("row.pay.title")),
                text: String.localizedStringWithFormat(String(localized: key("row.pay.text")), proNames)
            ))
        }
        if !free.isEmpty {
            rows.append(Row(
                symbol: "sparkles",
                title: String(localized: key("row.watermark.title")),
                text: String(localized: key("row.watermark.text"))
            ))
        }
        return rows
    }

    private static func names(of tricks: [Trick]) -> String? {
        guard !tricks.isEmpty else { return nil }
        return ListFormatter.localizedString(byJoining: tricks.map { String(localized: $0.title) })
    }

    // One key pair per counted text ("…one" / "…other"), like the onboarding pulse counter does.
    private static func countedText(key suffix: String, count: Int) -> String {
        let variant = count == 1 ? "one" : "other"
        return String.localizedStringWithFormat(String(localized: key("\(suffix).\(variant)")), count)
    }
}
