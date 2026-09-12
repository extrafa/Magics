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
    case hapticSettings
}

enum InstructionImageRatio: CGFloat {
    case standard = 0.75  // 3:4
    case compact  = 1.5   // 3:2
}

struct InstructionStep: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let phase: InstructionPhase
    let actions: [InstructionStepAction]
    let imageName: String?
    let imageRatio: InstructionImageRatio

    init(
        title: String,
        description: String,
        phase: InstructionPhase,
        actions: [InstructionStepAction] = [],
        imageName: String? = nil,
        imageRatio: InstructionImageRatio = .standard
    ) {
        self.title = title
        self.description = description
        self.phase = phase
        self.actions = actions
        self.imageName = imageName
        self.imageRatio = imageRatio
    }
}
