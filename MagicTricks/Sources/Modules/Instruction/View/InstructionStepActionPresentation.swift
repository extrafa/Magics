//
//  InstructionStepActionPresentation.swift
//  Magic Tricks
//
//  Created by Ross on 02/06/2026.
//

import Foundation

private let hapticTrainingKey = L10nDomain("instruction.action.hapticTraining")
private let hapticSettingsKey = L10nDomain("instruction.action.hapticSettings")

struct InstructionStepActionPresentation {
    let icon: String
    let title: String
    let subtitle: String

    init(action: InstructionStepAction) {
        switch action {
        case .hapticTraining:
            icon = "dot.radiowaves.left.and.right"
            title = String(localized: hapticTrainingKey("title"))
            subtitle = String(localized: hapticTrainingKey("subtitle"))
        case .hapticSettings:
            icon = "slider.horizontal.3"
            title = String(localized: hapticSettingsKey("title"))
            subtitle = String(localized: hapticSettingsKey("subtitle"))
        }
    }
}
