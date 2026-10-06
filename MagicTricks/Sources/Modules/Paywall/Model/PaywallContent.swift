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
    // Names, not a count: the sentence can't claim a number that drifts from the catalog.
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

        freeNote = Self.sentence(key("freeNote"), listing: freeTricks)
        focus = picked
        highlighted = picked?.id

        if let picked {
            headline = String.localizedStringWithFormat(String(localized: key("contextTitle")), String(localized: picked.title))
            subtitle = String.localizedStringWithFormat(String(localized: key("contextSubtitle")), tricks.count)
            effect = String(localized: picked.subtitle)
            unlocks = Self.sentence(key("alsoUnlocks"), listing: proTricks.filter { $0.id != picked.id })
        } else {
            headline = String(localized: key("title"))
            subtitle = String(localized: key("subtitle"))
            effect = nil
            unlocks = Self.sentence(key("unlocks"), listing: proTricks)
        }
    }

    private static func sentence(_ format: LocalizedStringResource, listing tricks: [Trick]) -> String? {
        guard !tricks.isEmpty else { return nil }
        let names = ListFormatter.localizedString(byJoining: tricks.map { String(localized: $0.title) })
        return String.localizedStringWithFormat(String(localized: format), names)
    }
}
