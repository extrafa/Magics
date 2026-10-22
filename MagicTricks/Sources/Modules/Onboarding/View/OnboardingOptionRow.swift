//
//  OnboardingOptionRow.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import SwiftUI

struct OnboardingOptionRow: View {
    let emoji: String
    let title: String
    let isSelected: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .callout) private var indicatorSize: CGFloat = 22

    var body: some View {
        // The emoji and indicator flank the title; at accessibility sizes they move to a row above it so words aren't split.
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(emoji)
                            .font(.title2)
                        Spacer()
                        selectionIndicator
                    }
                    titleText
                }
            } else {
                HStack(spacing: 14) {
                    Text(emoji)
                        .font(.title2)
                    titleText
                    Spacer()
                    selectionIndicator
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.textPrimary.opacity(0.06) : Color.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? Color.textPrimary.opacity(0.35) : Color.cardBorder, lineWidth: 1)
                }
        }
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var titleText: some View {
        Text(title)
            .font(.system(.callout, design: .rounded, weight: .medium))
            .foregroundStyle(.textPrimary)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.textPrimary)
                .font(.system(size: indicatorSize, weight: .semibold))
        } else {
            Circle()
                .stroke(Color.textPrimary.opacity(0.2), lineWidth: 1.5)
                .frame(width: indicatorSize, height: indicatorSize)
        }
    }
}
