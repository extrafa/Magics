//
//  PhantomDrawInstruction.swift
//  Magic Tricks
//

import Foundation

extension Instruction {
    static let phantomDraw = Instruction(
        title: String(localized: "instruction.phantomDraw.title"),
        effect: String(localized: "instruction.phantomDraw.effect"),
        secret: String(localized: "instruction.phantomDraw.secret"),
        steps: [
            InstructionStep(
                title: String(localized: "instruction.phantomDraw.step1.title"),
                description: String(localized: "instruction.phantomDraw.step1.description"),
                phase: .preparation
            ),
            InstructionStep(
                title: String(localized: "instruction.phantomDraw.step2.title"),
                description: String(localized: "instruction.phantomDraw.step2.description"),
                phase: .preparation
            ),
            InstructionStep(
                title: String(localized: "instruction.phantomDraw.step3.title"),
                description: String(localized: "instruction.phantomDraw.step3.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.phantomDraw.step4.title"),
                description: String(localized: "instruction.phantomDraw.step4.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.phantomDraw.step5.title"),
                description: String(localized: "instruction.phantomDraw.step5.description"),
                phase: .demonstration
            ),
        ]
    )
}
