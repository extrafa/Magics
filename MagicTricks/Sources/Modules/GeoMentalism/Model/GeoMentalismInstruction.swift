//
//  GeoMentalismInstruction.swift
//  Magic Tricks
//
//  Created by Ross on 29/07/2026.
//

import Foundation

extension Instruction {
    static let geoMentalism = Instruction(
        title: String(localized: "instruction.geo.title"),
        effect: String(localized: "instruction.geo.effect"),
        secret: String(localized: "instruction.geo.secret"),
        steps: [
            InstructionStep(
                title: String(localized: "instruction.geo.step1.title"),
                description: String(localized: "instruction.geo.step1.description"),
                phase: .preparation
            ),
            InstructionStep(
                title: String(localized: "instruction.geo.step2.title"),
                description: String(localized: "instruction.geo.step2.description"),
                phase: .demonstration,
                imageName: "geo.step.cityList"
            ),
            InstructionStep(
                title: String(localized: "instruction.geo.step3.title"),
                description: String(localized: "instruction.geo.step3.description"),
                phase: .demonstration,
                imageName: "geo.step.cityGrid"
            ),
            InstructionStep(
                title: String(localized: "instruction.geo.step4.title"),
                description: String(localized: "instruction.geo.step4.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.geo.step5.title"),
                description: String(localized: "instruction.geo.step5.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.geo.step6.title"),
                description: String(localized: "instruction.geo.step6.description"),
                phase: .demonstration
            )
        ]
    )
}
