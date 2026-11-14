//
//  TimeControlInstruction.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

private let key = L10nDomain("instruction.time")
private let stepImage = KeyDomain("step.time")

extension Instruction {
    static let timeControl = Instruction(
        trickType: .timeControl,
        title: String(localized: key("title")),
        effect: String(localized: key("effect")),
        secret: String(localized: key("secret")),
        steps: [
            InstructionStep(
                title: String(localized: key("step1.title")),
                description: String(localized: key("step1.description")),
                phase: .preparation,
                actions: [.hapticTraining]
            ),
            InstructionStep(
                title: String(localized: key("step2.title")),
                description: String(localized: key("step2.description")),
                phase: .preparation,
                actions: [.hapticSettings],
                imageName: stepImage("faceDown"),
                imageRatio: .compact
            ),
            InstructionStep(
                title: String(localized: key("step3.title")),
                description: String(localized: key("step3.description")),
                phase: .demonstration,
                imageName: stepImage("timer")
            ),
            InstructionStep(
                title: String(localized: key("step4.title")),
                description: String(localized: key("step4.description")),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: key("step5.title")),
                description: String(localized: key("step5.description")),
                phase: .demonstration
            ),
        ]
    )
}
