//
//  InstructionPhaseLegend.swift
//  Instruction
//
//  Created by Ross on 02/06/2026.
//

import SwiftUI

struct InstructionPhaseLegend: View {
    @ScaledMetric(relativeTo: .footnote) private var titleSize: CGFloat = 14

    var body: some View {
        HStack(spacing: 18) {
            legendItem(color: .blue, title: String(localized: "instruction.phase.preparation"))
            legendItem(color: .green, title: String(localized: "instruction.phase.demonstration"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.system(size: titleSize, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}
