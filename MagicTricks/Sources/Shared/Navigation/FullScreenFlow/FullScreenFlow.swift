//
//  FullScreenFlow.swift
//  Magic Tricks
//
//  Created by Ross on 07/01/2026.
//

import Foundation

enum FullScreenFlow: Identifiable, Equatable {

    case trick(trick: Trick)
    case paywall

    var id: String {
        switch self {
        case .trick(let trick): return "trick_\(trick.id)"
        case .paywall: return "paywall"
        }
    }
}
