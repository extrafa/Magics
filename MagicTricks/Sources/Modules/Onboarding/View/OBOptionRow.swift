//
//  OBOptionRow.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import SwiftUI

struct OBOptionRow: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    var isMultiSelect: Bool = true

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.title2)

            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.primaryText)

            Spacer()

            selectionIndicator
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.primaryText.opacity(0.06) : Color.grayCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? Color.primaryText.opacity(0.35) : Color.grayBorder, lineWidth: 1)
                }
        }
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.primaryText)
                .font(.system(size: 22, weight: .semibold))
        } else {
            Circle()
                .stroke(Color.primaryText.opacity(0.2), lineWidth: 1.5)
                .frame(width: 22, height: 22)
        }
    }
}
