//
//  TrickButtonStyles.swift
//  Magic Tricks
//
//  Created by Ross on 05/04/2026.
//

import SwiftUI

struct PrimaryTrickButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration, color: color)
    }

    // A ButtonStyle can't read the environment itself, so the disabled look lives in this inner view.
    private struct StyledLabel: View {
        let configuration: ButtonStyleConfiguration
        let color: Color
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .foregroundStyle(Color.backgroundScreen)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(color)
                }
                .opacity(isEnabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

struct SecondaryTrickButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration)
    }

    private struct StyledLabel: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .foregroundStyle(.textPrimary)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.textPrimary.opacity(0.16), lineWidth: 3)
                }
                .opacity(isEnabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

// The Shuffle button of the tricks whose items can be shuffled: wide, at the bottom of the screen.
struct ShuffleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "shuffle")
                    .font(.system(size: 17, weight: .semibold))
                    .accessibilityHidden(true)
                Text(String(localized: "common.shuffle"))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(PrimaryTrickButtonStyle(color: .buttonPrimary))
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }
}

