//
//  InstructionStepRow.swift
//  Instruction
//
//  Created by Ross on 02/06/2026.
//

import SwiftUI

struct InstructionStepRow: View {
    let number: Int
    let step: InstructionStep
    let onAction: (InstructionStepAction) -> Void

    init(
        number: Int,
        step: InstructionStep,
        onAction: @escaping (InstructionStepAction) -> Void = { _ in }
    ) {
        self.number = number
        self.step = step
        self.onAction = onAction
    }

    private var phaseColor: Color {
        switch step.phase {
        case .preparation: .blue
        case .demonstration: .green
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            content

            RoundedRectangle(cornerRadius: 999)
                .fill(phaseColor)
                .frame(width: 3)
        }
        .padding(.vertical, 12)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepText

            if let imageName = step.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.grayBorder, lineWidth: 1)
                    }
                    .frame(maxWidth: .infinity)
            }

            if !step.actions.isEmpty {
                InstructionStepActionsView(actions: step.actions, onAction: onAction)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepText: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number).")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primaryText.opacity(0.9))
                .frame(width: 32, alignment: .leading)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 12) {
                titleAndDescription
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleAndDescription: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(step.title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(step.description)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.primaryText.opacity(0.72))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ScrollView {
        InstructionStepRow(
            number: 1,
            step: InstructionStep(
                title: "Познакомьтесь с вибрациями",
                description: "Потренируйтесь различать сигналы вибрации.",
                phase: .preparation,
                actions: [.hapticTraining]
            )
        )
        .padding()
    }
}
