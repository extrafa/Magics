//
//  InstructionStepActionPresentation.swift
//  Magic Tricks
//
//  Created by Ross on 02/06/2026.
//

import Foundation

struct InstructionStepActionPresentation {
    let icon: String
    let title: String
    let subtitle: String

    init(action: InstructionStepAction) {
        switch action {
        case .hapticTraining:
            icon = "dot.radiowaves.left.and.right"
            title = String(localized: "instruction.action.hapticTraining.title")
            subtitle = String(localized: "instruction.action.hapticTraining.subtitle")
        case .hapticNumberTraining:
            icon = "dot.radiowaves.left.and.right"
            title = String(localized: "instruction.action.hapticNumberTraining.title")
            subtitle = String(localized: "instruction.action.hapticNumberTraining.subtitle")
        case .hapticSettings:
            icon = "slider.horizontal.3"
            title = String(localized: "instruction.action.hapticSettings.title")
            subtitle = String(localized: "instruction.action.hapticSettings.subtitle")
        case .motionSettings:
            icon = "iphone.radiowaves.left.and.right"
            title = String(localized: "instruction.action.motionSettings.title")
            subtitle = String(localized: "instruction.action.motionSettings.subtitle")
        }
    }
}
