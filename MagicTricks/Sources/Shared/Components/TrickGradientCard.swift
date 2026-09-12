//
//  TrickGradientCard.swift
//  Magic Tricks
//
//  Created by Ross on 05/04/2026.
//

import SwiftUI

struct TrickGradientCard<Content: View>: View {

    let color: Color
    let height: CGFloat
    let isPressed: Bool
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(1.0),
                            color.opacity(colorScheme == .dark ? 0.62 : 0.88)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 110
                    )
                )

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.18 : 0.28),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.55)
                    )
                )

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(isPressed ? 0.5 : 0.2), lineWidth: 1)

            content()
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .shadow(
            color: color.opacity(colorScheme == .dark ? 0.32 : 0.22),
            radius: isPressed ? 8 : 18,
            x: 0,
            y: isPressed ? 4 : 10
        )
        .scaleEffect(isPressed ? 0.965 : 1)
        .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}

extension TrickGradientCard where Content == EmptyView {
    init(color: Color, height: CGFloat, isPressed: Bool) {
        self.init(color: color, height: height, isPressed: isPressed) { EmptyView() }
    }
}
