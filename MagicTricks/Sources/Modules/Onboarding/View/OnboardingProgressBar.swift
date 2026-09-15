//
//  OnboardingProgressBar.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import SwiftUI

struct OnboardingProgressBar: View {
    let step: Int
    let total: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.primaryText.opacity(0.1))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.primaryText)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
            }
        }
        .frame(height: 4)
    }

    private var progress: CGFloat {
        CGFloat(step) / CGFloat(total)
    }
}
