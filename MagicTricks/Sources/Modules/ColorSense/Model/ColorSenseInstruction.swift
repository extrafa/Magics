//
//  ColorMentalismInstruction.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

extension Instruction {
    static let colorSense = Instruction(
        title: String(localized: "instruction.color.title"),
        effect: String(localized: "instruction.color.effect"),
        secret: String(localized: "instruction.color.secret"),
        steps: [
            InstructionStep(
                title: String(localized: "instruction.color.step1.title"),
                description: String(localized: "instruction.color.step1.description"),
                phase: .preparation,
                actions: [.hapticTraining, .hapticSettings]
            ),
            InstructionStep(
                title: String(localized: "instruction.color.step2.title"),
                description: String(localized: "instruction.color.step2.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.color.step3.title"),
                description: String(localized: "instruction.color.step3.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.color.step4.title"),
                description: String(localized: "instruction.color.step4.description"),
                phase: .demonstration,
                imageName: "color.step.colorGrid"
            ),
            InstructionStep(
                title: String(localized: "instruction.color.step5.title"),
                description: String(localized: "instruction.color.step5.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.color.step6.title"),
                description: String(localized: "instruction.color.step6.description"),
                phase: .demonstration
            )
        ]
    )
}
