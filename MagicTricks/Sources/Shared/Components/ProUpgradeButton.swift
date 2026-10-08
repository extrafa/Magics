//
//  ProUpgradeButton.swift
//  Magic Tricks
//
//  Created by Ross on 11/08/2026.
//

import SwiftUI

struct ProUpgradeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(String(localized: "pro.upgradeButton.title"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background { capsule }
        }
    }

    // MARK: Capsule

    private var capsule: some View {
        Capsule()
            .fill(TrickPalette.proGradient)
            .shimmer(in: Capsule())
    }
}

#Preview {
    ProUpgradeButton(action: {})
        .padding()
}
