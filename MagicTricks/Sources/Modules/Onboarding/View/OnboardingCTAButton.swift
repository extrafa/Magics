//
//  OnboardingCTAButton.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import SwiftUI

struct OnboardingCTAButton: View {
    let title: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    // What VoiceOver says when it should be more than the visible title.
    var accessibilityText: String?
    let action: () -> Void

    // Grows with Dynamic Type (up to a cap), so a longer label wraps inside the button instead of being cut off.
    @ScaledMetric(relativeTo: .headline) private var height: CGFloat = 56
    @ScaledMetric(relativeTo: .headline) private var fontSize: CGFloat = 18

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Color.backgroundScreen)
                } else {
                    Text(title)
                        .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 12)
            // Only the empty minimum is capped: the label keeps growing and a longer one still wraps inside the button.
            .frame(maxWidth: .infinity, minHeight: min(height, 72))
            .background(isEnabled ? Color.textPrimary : Color.textPrimary.opacity(0.3))
            .foregroundStyle(Color.backgroundScreen)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .animation(.easeOut(duration: 0.2), value: isEnabled)
        }
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(accessibilityText ?? title)
    }
}
