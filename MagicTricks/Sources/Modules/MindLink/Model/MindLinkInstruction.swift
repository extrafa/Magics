//
//  MindLinkInstruction.swift
//  Magic Tricks
//

import Foundation

extension Instruction {
    static let mindLink = Instruction(
        title: String(localized: "instruction.mindLink.title"),
        effect: String(localized: "instruction.mindLink.effect"),
        secret: String(localized: "instruction.mindLink.secret"),
        steps: [
            InstructionStep(
                title: String(localized: "instruction.mindLink.step1.title"),
                description: String(localized: "instruction.mindLink.step1.description"),
                phase: .preparation
            ),
            InstructionStep(
                title: String(localized: "instruction.mindLink.step2.title"),
                description: String(localized: "instruction.mindLink.step2.description"),
                phase: .preparation
            ),
            InstructionStep(
                title: String(localized: "instruction.mindLink.step3.title"),
                description: String(localized: "instruction.mindLink.step3.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.mindLink.step4.title"),
                description: String(localized: "instruction.mindLink.step4.description"),
                phase: .demonstration
            ),
        ]
    )
}
