//
//  TrickDifficultyBadge.swift
//  Magic Tricks
//
//  Created by Ross on 10/04/2026.
//

import SwiftUI

struct TrickDifficultyBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    let difficulty: TrickDifficulty

    var body: some View {
        Text(difficulty.localizedTitle.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(difficulty.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Capsule(style: .continuous).fill(badgeFillColor))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(badgeStrokeColor, lineWidth: colorScheme == .light ? 1.2 : 1.4)
            }
            .overlay {
                if colorScheme == .dark {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
            }
            .shadow(color: badgeShadowColor, radius: 8, x: 0, y: 4)
    }

    private var badgeFillColor: Color {
        difficulty.color.opacity(colorScheme == .light ? 0.14 : 0.15)
    }

    private var badgeStrokeColor: Color {
        difficulty.color.opacity(colorScheme == .light ? 0.42 : 0.48)
    }

    private var badgeShadowColor: Color {
        difficulty.color.opacity(colorScheme == .light ? 0.08 : 0.18)
    }
}
