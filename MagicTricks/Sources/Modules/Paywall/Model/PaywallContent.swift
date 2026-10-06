//
//  PaywallContent.swift
//  Magic Tricks
//

import Foundation

private let key = L10nDomain("paywall")

struct PaywallTrick: Identifiable {
    let trick: Trick
    let effect: String

    var id: TrickType { trick.id }
}

// What the paywall says and in which order: the one place to tune copy and trick order.
struct PaywallContent {
    let headline: String
    let subtitle: String
    let highlighted: PaywallTrick?
    let others: [PaywallTrick]

    var tricks: [PaywallTrick] {
        (highlighted.map { [$0] } ?? []) + others
    }

    init(context: PaywallContext, tricks: [Trick] = TrickCollection.tricks) {
        let proTricks = tricks.compactMap { trick -> PaywallTrick? in
            guard trick.id.requiresPro, let effect = trick.id.paywallEffect else { return nil }
            return PaywallTrick(trick: trick, effect: effect)
        }

        if case .trick(let type) = context, let picked = proTricks.first(where: { $0.id == type }) {
            let rest = proTricks.filter { $0.id != type }
            highlighted = picked
            others = rest
            headline = String.localizedStringWithFormat(String(localized: key("contextTitle")), String(localized: picked.trick.title))
            subtitle = String.localizedStringWithFormat(String(localized: key("contextSubtitle")), rest.count)
        } else {
            highlighted = nil
            others = proTricks
            headline = String(localized: key("title"))
            subtitle = String.localizedStringWithFormat(String(localized: key("subtitle")), proTricks.count)
        }
    }
}

extension TrickType {
    // Exhaustive on purpose: a new trick won't compile until it decides what the paywall says about it.
    var paywallEffect: String? {
        switch self {
        case .geoMentalism: nil
        case .colorSense: String(localized: key("effect.colorSense"))
        case .calculatorPrediction: String(localized: key("effect.calculatorPrediction"))
        case .timeControl: String(localized: key("effect.timeControl"))
        case .magicGallery: String(localized: key("effect.magicGallery"))
        case .phantomDraw: String(localized: key("effect.phantomDraw"))
        }
    }
}
