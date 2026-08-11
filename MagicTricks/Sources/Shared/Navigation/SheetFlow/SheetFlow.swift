//
//  SheetFlow.swift
//  Magic Tricks
//
//  Created by Ross on 11/01/2026.
//

import Foundation

enum SheetFlow: Identifiable, Equatable {
    case instruction(instruction: Instruction)
    case instructionFirstLaunch(instruction: Instruction, trick: Trick)

    var id: String {
        switch self {
        case .instruction(let instruction): return "instruction_\(instruction.title)"
        case .instructionFirstLaunch(let instruction, _): return "firstLaunch_\(instruction.title)"
        }
    }
}
