//
//  ColorMentalismView.swift
//  Magic Tricks
//
//  Created by Ross on 05/04/2026.
//

import SwiftUI

struct ColorMentalismView: View {

    @StateObject private var viewModel: ColorMentalismViewModel
    @State private var isVisible = true

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    init(haptics: CountHapticPlaying? = nil) {
        _viewModel = StateObject(wrappedValue: ColorMentalismViewModel(haptics: haptics ?? HapticManager.shared))
    }

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                    let motion = floatingMotionSettings(for: index)

                    cardView(card)
                        .rotationEffect(.degrees(card.rotation))
                        .floatingMotion(
                            phase: motion.phase,
                            travel: motion.travel,
                            rotation: motion.rotation,
                            duration: motion.duration
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in viewModel.handleTap(on: card) }
                        )
                }
            }
            .padding(.horizontal, 20)

            ExitHintView(isVisible: $isVisible)
        }
        .onDisappear {
            viewModel.cancel()
        }
    }

    private func cardView(_ card: ColorCard) -> some View {
        TrickGradientCard(
            color: card.colorType.color,
            height: card.height,
            isPressed: viewModel.activeTapCardID == card.id
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Spacer()
                Text(card.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func floatingMotionSettings(for index: Int) -> FloatingMotionModifier {
        FloatingMotionModifier(
            phase: Double(index) * 0.18,
            travel: CGFloat(2.2 + Double(index % 3) * 0.55),
            rotation: 0.7 + Double(index % 4) * 0.18,
            duration: 3.4 + Double(index % 3) * 0.45
        )
    }
}

#Preview {
    ColorMentalismView()
}
