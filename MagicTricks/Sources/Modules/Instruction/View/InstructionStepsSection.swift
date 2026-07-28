//
//  InstructionStepsSection.swift
//  Instruction
//
//  Created by Ross on 02/06/2026.
//

import SwiftUI

struct InstructionStepsSection: View {
    let steps: [InstructionStep]
    let onAction: (InstructionStepAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "instruction.section.steps"))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primaryText)

            InstructionPhaseLegend()

            rows
                .padding(.vertical, 6)
        }
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                InstructionStepRow(
                    number: index + 1,
                    step: step,
                    onAction: onAction
                )

                if index < steps.count - 1 {
                    Divider()
                        .overlay(Color.white.opacity(0.06))
                        .padding(.leading, 46)
                }
            }
        }
    }
}
