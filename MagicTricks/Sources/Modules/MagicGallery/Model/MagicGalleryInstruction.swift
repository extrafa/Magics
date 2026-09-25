//
//  MagicGalleryInstruction.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

private let key = L10nDomain("instruction.magicGallery")

extension Instruction {
    static let magicGallery = Instruction(
        trickType: .magicGallery,
        title: String(localized: key("title")),
        effect: String(localized: key("effect")),
        secret: String(localized: key("secret")),
        steps: [
            InstructionStep(
                title: String(localized: key("step1.title")),
                description: String(localized: key("step1.description")),
                phase: .preparation,
                imageName: "step.gallery.collection"
            ),
            InstructionStep(
                title: String(localized: key("step2.title")),
                description: String(localized: key("step2.description")),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: key("step3.title")),
                description: String(localized: key("step3.description")),
                phase: .demonstration
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
