//
//  MagicGalleryInstruction.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

extension Instruction {
    static let magicGallery = Instruction(
        title: String(localized: "instruction.magicGallery.title"),
        effect: String(localized: "instruction.magicGallery.effect"),
        secret: String(localized: "instruction.magicGallery.secret"),
        steps: [
            InstructionStep(
                title: String(localized: "instruction.magicGallery.step1.title"),
                description: String(localized: "instruction.magicGallery.step1.description"),
                phase: .preparation,
                imageName: "gallery.step.collection"
            ),
            InstructionStep(
                title: String(localized: "instruction.magicGallery.step2.title"),
                description: String(localized: "instruction.magicGallery.step2.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.magicGallery.step3.title"),
                description: String(localized: "instruction.magicGallery.step3.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.magicGallery.step4.title"),
                description: String(localized: "instruction.magicGallery.step4.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.magicGallery.step5.title"),
                description: String(localized: "instruction.magicGallery.step5.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.magicGallery.step6.title"),
                description: String(localized: "instruction.magicGallery.step6.description"),
                phase: .demonstration
            ),
        ]
    )
}
