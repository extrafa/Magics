//
//  PaywallContent.swift
//  Magic Tricks
//

import Foundation

private let key = L10nDomain("paywall")

struct PaywallRow: Identifiable {
    enum Kind {
        case trick(Trick)
        case noWatermark
    }

    let kind: Kind
    let isFree: Bool

    var id: String {
        switch kind {
        case .trick(let trick): trick.id.rawValue
        case .noWatermark: "noWatermark"
        }
    }

    var trickType: TrickType? {
        if case .trick(let trick) = kind { trick.id } else { nil }
    }

    var title: String {
        switch kind {
        case .trick(let trick): String(localized: trick.title)
        case .noWatermark: String(localized: key("row.noWatermark"))
        }
    }
}

// What the paywall says and what it lists: the one place to tune copy and rows.
// Rows come straight from TrickCollection, so a new trick shows up on the paywall by itself.
struct PaywallContent {
    let headline: String
    let subtitle: String
    let rows: [PaywallRow]
    let highlighted: TrickType?

    // The tapped Pro trick (contextual paywall) and what it does; nil on the general paywall.
    let focus: Trick?
    let effect: String?
    // The count is derived from the catalog (never typed into copy), so it can't drift from what the purchase opens.
    let unlocks: String?
    let freeNote: String?

    init(context: PaywallContext, tricks: [Trick] = TrickCollection.tricks) {
        var rows = tricks.map { PaywallRow(kind: .trick($0), isFree: !$0.id.requiresPro) }
        rows.append(PaywallRow(kind: .noWatermark, isFree: false))
        self.rows = rows

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
        highlighted = picked?.id

        if let picked {
            headline = String.localizedStringWithFormat(String(localized: key("contextTitle")), String(localized: picked.title))
            subtitle = String.localizedStringWithFormat(String(localized: key("contextSubtitle")), tricks.count)
            effect = String(localized: picked.subtitle)
            unlocks = Self.countedSentence(key: "alsoUnlocks", listing: proTricks.filter { $0.id != picked.id })
        } else {
            headline = String(localized: key("title"))
            subtitle = String(localized: key("subtitle"))
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
