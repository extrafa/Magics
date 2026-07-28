//
//  InstructionShareFormatter.swift
//  Magic Tricks
//
//  Created by Ross on 17/04/2026.
//

import Foundation

enum InstructionShareFormatter {
    static func shareText(for instruction: Instruction) -> String {
        let effect = String(localized: "instruction.section.effect")
        let secret = String(localized: "instruction.section.secret")
        let steps = String(localized: "instruction.section.steps")
        let madeWith = String(localized: "instruction.share.madeWith")
        let learnMore = String(localized: "instruction.share.learnMore")

        let stepsText = instruction.steps.enumerated()
            .map { index, step in "\(index + 1). \(step.title)\n\(step.description)" }
            .joined(separator: "\n\n")

        return """
        \(instruction.title)

        \(effect)
        \(instruction.effect)

        \(secret)
        \(instruction.secret)

        \(steps)
        \(stepsText)

        \(madeWith)
        \(learnMore)
        """
    }
}
