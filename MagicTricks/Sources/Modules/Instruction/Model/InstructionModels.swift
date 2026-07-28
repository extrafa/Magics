//
//  InstructionModels.swift
//  Instruction
//
//  Created by Ross on 09/04/2026.
//

import Foundation

struct Instruction: Equatable, Hashable {
    let title: String
    let effect: String
    let secret: String
    let steps: [InstructionStep]
}

enum InstructionStepAction: Hashable {
    case hapticTraining
    case hapticNumberTraining
    case hapticSettings
    case motionSettings
}

struct InstructionStep: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let phase: InstructionPhase
    let actions: [InstructionStepAction]

    init(
        title: String,
        description: String,
        phase: InstructionPhase,
        actions: [InstructionStepAction] = []
    ) {
        self.title = title
        self.description = description
        self.phase = phase
        self.actions = actions
    }
}
