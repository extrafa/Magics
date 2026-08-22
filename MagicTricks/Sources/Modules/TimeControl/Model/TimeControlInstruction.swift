//
//  TimeControlInstruction.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

extension Instruction {
    static let timeControl = Instruction(
        title: String(localized: "instruction.time.title"),
        effect: String(localized: "instruction.time.effect"),
        secret: String(localized: "instruction.time.secret"),
        steps: [
            InstructionStep(
                title: String(localized: "instruction.time.step1.title"),
                description: String(localized: "instruction.time.step1.description"),
                phase: .preparation,
                actions: [.hapticTraining]
            ),
            InstructionStep(
                title: String(localized: "instruction.time.step2.title"),
                description: String(localized: "instruction.time.step2.description"),
                phase: .preparation,
                actions: [.hapticSettings],
                imageName: "time.step.faceDown",
                imageRatio: .compact
            ),
            InstructionStep(
                title: String(localized: "instruction.time.step3.title"),
                description: String(localized: "instruction.time.step3.description"),
                phase: .demonstration,
                imageName: "time.step.timer"
            ),
            InstructionStep(
                title: String(localized: "instruction.time.step4.title"),
                description: String(localized: "instruction.time.step4.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.time.step5.title"),
                description: String(localized: "instruction.time.step5.description"),
                phase: .demonstration
            ),
        ]
    )
}
