//
//  InstructionPresentedSheet.swift
//  Instruction
//
//  Created by Ross on 02/06/2026.
//

import Foundation

enum InstructionPresentedSheet: Identifiable {
    case action(InstructionStepAction)

    var id: String {
        switch self {
        case .action(let action): "\(action)"
        }
    }
}
