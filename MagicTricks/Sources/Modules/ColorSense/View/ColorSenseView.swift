//
//  ColorSenseView.swift
//  Magic Tricks
//
//  Created by Ross on 05/04/2026.
//

import SwiftUI

struct ColorSenseView: View {

    @StateObject private var viewModel: ColorSenseViewModel

    private static let columns = [
        GridItem(.flexible(), spacing: ColorSenseViewModel.gridSpacing),
        GridItem(.flexible(), spacing: ColorSenseViewModel.gridSpacing)
    ]
    // Room for the cards' floating motion, so the moving grid never touches the screen edge.
    private static let motionMargin: CGFloat = 24

    init(haptics: CountHapticPlaying? = nil) {
        _viewModel = StateObject(wrappedValue: ColorSenseViewModel(haptics: haptics ?? HapticManager.shared))
    }

    var body: some View {
        ZStack {
            Color.backgroundScreen.ignoresSafeArea()

            GeometryReader { geo in
                let heightScale = viewModel.heightScale(forAvailableHeight: geo.size.height - Self.motionMargin)
                LazyVGrid(columns: Self.columns, spacing: ColorSenseViewModel.gridSpacing) {
                    ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                        cardView(card, heightScale: heightScale)
                            .rotationEffect(.degrees(card.rotation))
                            .modifier(floatingMotionSettings(for: index))
                            .onTapGesture { viewModel.handleTap(on: card) }
                    }
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .exitHint()
        .keepsScreenAwake()
        .hapticsUnavailableNoticeOverlay()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // On the spectator's screen like in Geo Mentalism: it marks the free tier and paying removes it.
                WatermarkView()
            }
        }
        .onDisappear {
            viewModel.cancel()
        }
    }

    private func cardView(_ card: ColorCard, heightScale: CGFloat) -> some View {
        TrickGradientCard(
            color: card.colorType.color,
            height: card.height * heightScale,
            isPressed: viewModel.activeTapCardID == card.id
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Spacer()
                Text(card.title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    // A decoy word on a fixed-size card: capped so it never truncates or splits.
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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

private extension ColorCardType {
    var color: Color {
        switch self {
        case .red:    TrickPalette.ColorSense.red
        case .blue:   TrickPalette.ColorSense.blue
        case .green:  TrickPalette.ColorSense.green
        case .yellow: TrickPalette.ColorSense.yellow
        }
    }
}

#Preview {
    ColorSenseView()
}
