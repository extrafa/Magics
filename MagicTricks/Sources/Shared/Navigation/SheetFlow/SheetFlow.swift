//
//  SheetFlow.swift
//  Magic Tricks
//
//  Created by Ross on 11/01/2026.
//

import Foundation

enum SheetFlow: Identifiable, Equatable {
    // The instruction always comes with the trick, so its Start Trick button can start it.
    case instruction(instruction: Instruction, trick: Trick)
    case rateApp

    var id: String {
        switch self {
        case .instruction(let instruction, _): return "instruction_\(instruction.trickType.rawValue)"
        case .rateApp: return "rateApp"
        }
    }
}
