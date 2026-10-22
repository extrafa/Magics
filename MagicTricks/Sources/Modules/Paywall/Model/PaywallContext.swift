//
//  PaywallContext.swift
//  Magic Tricks
//

import Foundation

// What the user was doing when the paywall opened, so it can speak to that.
enum PaywallContext: Equatable {
    case general
    case trick(TrickType)
}
