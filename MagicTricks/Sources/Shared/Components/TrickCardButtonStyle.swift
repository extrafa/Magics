//
//  TrickCardButtonStyle.swift
//  Magic Tricks
//
//  Created by Ross on 05/04/2026.
//
// Unused — TrickGradientCard handles press state via its `isPressed` parameter directly.
// Safe to delete this file from the project.

import SwiftUI

struct TrickCardButtonStyle: ButtonStyle {
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(pressed ? 0.5 : 0.2), lineWidth: 1)
            }
            .shadow(
                color: color.opacity(colorScheme == .dark ? 0.32 : 0.22),
                radius: pressed ? 8 : 18,
                x: 0,
                y: pressed ? 4 : 10
            )
            .scaleEffect(pressed ? 0.965 : 1)
            .animation(.easeOut(duration: 0.12), value: pressed)
    }
}
