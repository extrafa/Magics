//
//  InstructionPhaseLegend.swift
//  Instruction
//
//  Created by Ross on 02/06/2026.
//

import SwiftUI

private let key = L10nDomain("instruction.phase")

struct InstructionPhaseLegend: View {
    @ScaledMetric(relativeTo: .footnote) private var titleSize: CGFloat = 14

    var body: some View {
        // Stacks the items once a single row no longer fits, so a word is never split mid-way.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 18) { items }
            VStack(alignment: .leading, spacing: 8) { items }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var items: some View {
        legendItem(color: InstructionPhase.preparation.color, title: String(localized: key("preparation")))
        legendItem(color: InstructionPhase.demonstration.color, title: String(localized: key("demonstration")))
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
