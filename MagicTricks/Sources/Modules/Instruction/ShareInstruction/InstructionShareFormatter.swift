//
//  InstructionShareFormatter.swift
//  Magic Tricks
//
//  Created by Ross on 17/04/2026.
//

import Foundation

private let sectionKey = L10nDomain("instruction.section")
private let shareKey = L10nDomain("instruction.share")

enum InstructionShareFormatter {
    static func shareText(for instruction: Instruction) -> String {
        let effect = String(localized: sectionKey("effect"))
        let secret = String(localized: sectionKey("secret"))
        let steps = String(localized: sectionKey("steps"))
        let madeWith = String(localized: shareKey("madeWith"))
        let learnMore = String(localized: shareKey("learnMore"))

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
