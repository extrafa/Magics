//
//  PaywallContent.swift
//  Magic Tricks
//

import Foundation

private let key = L10nDomain("paywall")

// What the paywall says and which cards it deals: the one place to tune copy.
// Cards come straight from TrickCollection, so a new Pro trick shows up on the paywall by itself.
struct PaywallContent {
    let headline: String
    // The Pro tricks in collection order; the tapped one goes last, so it lies on top of the fan.
    let cards: [Trick]

    // The tapped Pro trick (contextual paywall) and what it does; nil on the general paywall.
    let focus: Trick?
    let effect: String?
    // The count is derived from the catalog (never typed into copy), so it can't drift from what the purchase opens.
    let unlocks: String?
    let freeNote: String?

    init(context: PaywallContext, tricks: [Trick] = TrickCollection.tricks) {
        let proTricks = tricks.filter { $0.id.requiresPro }
        let freeTricks = tricks.filter { !$0.id.requiresPro }
        let picked: Trick?
        if case .trick(let type) = context {
            picked = proTricks.first { $0.id == type }
        } else {
            picked = nil
        }

        freeNote = Self.names(of: freeTricks).map {
            String.localizedStringWithFormat(String(localized: key("freeNote")), $0)
        }
        focus = picked
        cards = proTricks.filter { $0.id != picked?.id } + (picked.map { [$0] } ?? [])

        if let picked {
            headline = String.localizedStringWithFormat(String(localized: key("contextTitle")), String(localized: picked.title))
            effect = String(localized: picked.subtitle)
            unlocks = Self.countedSentence(key: "alsoUnlocks", listing: proTricks.filter { $0.id != picked.id })
        } else {
            headline = String(localized: key("title"))
            effect = nil
            unlocks = Self.countedSentence(key: "unlocks", listing: proTricks)
        }
    }

    private static func names(of tricks: [Trick]) -> String? {
        guard !tricks.isEmpty else { return nil }
        return ListFormatter.localizedString(byJoining: tricks.map { String(localized: $0.title) })
    }

    // "5 more tricks: A, B and C." One key pair per sentence, like the onboarding pulse counter does.
    private static func countedSentence(key suffix: String, listing tricks: [Trick]) -> String? {
        guard let names = names(of: tricks) else { return nil }
        let variant = tricks.count == 1 ? "one" : "other"
        let format = String(localized: key("\(suffix).\(variant)"))
        return String.localizedStringWithFormat(format, tricks.count, names)
    }
}
