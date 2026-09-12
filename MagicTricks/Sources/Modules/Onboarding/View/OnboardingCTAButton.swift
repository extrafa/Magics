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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Color.background)
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isEnabled ? Color.primaryText : Color.primaryText.opacity(0.3))
            .foregroundStyle(Color.background)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .animation(.easeOut(duration: 0.2), value: isEnabled)
        }
        .disabled(!isEnabled || isLoading)
    }
}
