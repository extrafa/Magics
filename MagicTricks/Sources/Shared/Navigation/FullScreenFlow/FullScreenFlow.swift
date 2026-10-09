//
//  FullScreenFlow.swift
//  Magic Tricks
//
//  Created by Ross on 07/01/2026.
//

import Foundation

// What the user was doing when the paywall opened, so it can speak to that.
enum PaywallContext: Equatable {
    case general
    case trick(TrickType)
}

enum FullScreenFlow: Identifiable, Equatable {

    case trick(trick: Trick)
    case paywall(context: PaywallContext)

    var id: String {
        switch self {
        case .trick(let trick): return "trick_\(trick.id.rawValue)"
        case .paywall(.general): return "paywall"
        case .paywall(.trick(let type)): return "paywall_\(type.rawValue)"
        }
    }
}
