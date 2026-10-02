//
//  InstructionComponents.swift
//  Instruction
//
//  Created by Ross on 09/04/2026.
//

import SwiftUI

private let sectionKey = L10nDomain("instruction.section")

struct InstructionBlock: View {
    let text: String

    var body: some View {
        InstructionInfoCard(
            icon: "sparkles",
            title: String(localized: sectionKey("effect")),
            text: text,
            iconOpacity: 0.85,
            textOpacity: 0.8,
            fillOpacity: 0.045,
            strokeOpacity: 0.08
        )
    }
}

struct InstructionSecretView: View {
    let text: String

    var body: some View {
        InstructionInfoCard(
            icon: "lock.fill",
            title: String(localized: sectionKey("secret")),
            text: text,
            iconOpacity: 0.82,
            textOpacity: 0.78,
            fillOpacity: 0.06,
            strokeOpacity: 0.1
        )
    }
}

private struct InstructionInfoCard: View {
    let icon: String
    let title: String
    let text: String
    let iconOpacity: Double
    let textOpacity: Double
    let fillOpacity: Double
    let strokeOpacity: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.textPrimary.opacity(iconOpacity))
                    .frame(width: 22, alignment: .leading)

                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.textPrimary)
            }

            Text(text)
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.textPrimary.opacity(textOpacity))
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.textPrimary.opacity(fillOpacity))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.textPrimary.opacity(strokeOpacity), lineWidth: 1)
                }
        }
    }
}
