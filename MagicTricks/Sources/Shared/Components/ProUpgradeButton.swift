//
//  ProUpgradeButton.swift
//  Magic Tricks
//
//  Created by Ross on 11/08/2026.
//

import SwiftUI

struct ProUpgradeButton: View {
    let action: () -> Void
    @State private var shimmer = false

    var body: some View {
        Button(action: action) {
            Text("Get Pro")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background { capsule }
        }
        .task { await shimmerLoop() }
    }

    // MARK: Capsule

    private var capsule: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.58, blue: 0.08),
                        Color(red: 1.0, green: 0.28, blue: 0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(shimmerLayer)
    }

    // MARK: Shimmer

    private var shimmerLayer: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.38), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.5)
            .offset(x: shimmer ? geo.size.width * 1.2 : -geo.size.width * 0.5)
        }
        .clipShape(Capsule())
        .blendMode(.screen)
        .allowsHitTesting(false)
    }

    private func shimmerLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(seconds: 2.5)
            withAnimation(.easeInOut(duration: 0.75)) { shimmer = true }
            try? await Task.sleep(milliseconds: 950)
            shimmer = false
        }
    }
}

#Preview {
    ProUpgradeButton(action: {})
        .padding()
}
