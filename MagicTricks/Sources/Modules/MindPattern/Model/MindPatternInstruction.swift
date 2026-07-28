//
//  MindPatternInstruction.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

extension Instruction {
    static let mindPattern = Instruction(
        title: String(localized: "instruction.mindPattern.title"),
        effect: String(localized: "instruction.mindPattern.effect"),
        secret: String(localized: "instruction.mindPattern.secret"),
        steps: [
            InstructionStep(
                title: String(localized: "instruction.mindPattern.step1.title"),
                description: String(localized: "instruction.mindPattern.step1.description"),
                phase: .preparation,
                actions: [.hapticTraining]
            ),
            InstructionStep(
                title: String(localized: "instruction.mindPattern.step2.title"),
                description: String(localized: "instruction.mindPattern.step2.description"),
                phase: .preparation
            ),
            InstructionStep(
                title: String(localized: "instruction.mindPattern.step3.title"),
                description: String(localized: "instruction.mindPattern.step3.description"),
                phase: .preparation
            ),
            InstructionStep(
                title: String(localized: "instruction.mindPattern.step4.title"),
                description: String(localized: "instruction.mindPattern.step4.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.mindPattern.step5.title"),
                description: String(localized: "instruction.mindPattern.step5.description"),
                phase: .demonstration,
                actions: [.motionSettings]
            ),
            InstructionStep(
                title: String(localized: "instruction.mindPattern.step6.title"),
                description: String(localized: "instruction.mindPattern.step6.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.mindPattern.step7.title"),
                description: String(localized: "instruction.mindPattern.step7.description"),
                phase: .demonstration
            ),
        ]
    )
}
