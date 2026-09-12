//
//  InstructionActionSheetDestination.swift
//  Instruction
//
//  Created by Ross on 02/06/2026.
//

import SwiftUI

struct InstructionActionSheetDestination: View {
    let sheet: InstructionPresentedSheet

    var body: some View {
        switch sheet {
        case .action(let action):
            destination(for: action)
        }
    }

    @ViewBuilder
    private func destination(for action: InstructionStepAction) -> some View {
        switch action {
        case .hapticTraining:
            HapticTrainingView()
        case .hapticSettings:
            HapticSettingsScreen()
        }
    }
}
