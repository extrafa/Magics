//
//  ColorSenseView.swift
//  Magic Tricks
//
//  Created by Ross on 05/04/2026.
//

import SwiftUI

struct ColorSenseView: View {

    @StateObject private var viewModel: ColorSenseViewModel
    @StateObject private var flight = ShuffleFlight<UUID>()
    @EnvironmentObject private var store: StoreManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shakeGate = ShakeShuffleGate()

    private static let columns = [
        GridItem(.flexible(), spacing: ColorSenseViewModel.gridSpacing),
        GridItem(.flexible(), spacing: ColorSenseViewModel.gridSpacing)
    ]
    // Room for the cards' floating motion, so the moving grid never touches the screen edge.
    private static let motionMargin: CGFloat = 24
    // The band at the top for the watermark: as tall as the watermark and the navigation bar it was in, so the cards sit where they always did.
    private static let watermarkBand = WatermarkView.floatingHeight

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
                            .rotationEffect(.degrees(card.rotation + (flight.tilt[card.id] ?? 0)))
                            .modifier(floatingMotionSettings(for: index))
                            .onTapGesture { viewModel.handleTap(on: card) }
                            .animation(reduceMotion ? nil : ShuffleFlight<UUID>.wave(at: index), value: viewModel.cards.map(\.id))
                    }
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Below the watermark band, so the notice never lies over the watermark.
        .hapticsUnavailableNoticeOverlay()
        .safeAreaInset(edge: .top, spacing: 0) {
            watermarkBand
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // While a signal is on its way the cards ignore taps, and so does this button: it just does not react, it does not change.
            ShuffleButton(action: shuffle)
                .allowsHitTesting(viewModel.canTap)
        }
        // A shake shuffles at once, like the button. There is no buzz for it: here the vibrations are the secret signal.
        .onShake(
            began: {
                if shakeGate.began() { shuffle() }
            },
            ended: {
                if shakeGate.ended() { shuffle() }
            },
            cancelled: { shakeGate.cancelled() }
        )
        // The exit hint comes after, so it lies above the watermark; it keeps to the corner of the screen like in the other tricks.
        .exitHint()
        .keepsScreenAwake()
        // No navigation bar: the watermark used to sit in it, and closing the watermark made the bar collapse and everything jump up.
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear {
            viewModel.cancel()
        }
    }

    // On the spectator's screen like in Geo Mentalism: it marks the free tier and paying removes it. Its place stays free after it is closed,
    // so closing it moves nothing.
    private var watermarkBand: some View {
        HStack {
            Spacer()
            WatermarkView(isFloating: true)
        }
        .padding(.horizontal, 16)
        .frame(height: WatermarkView.canShow(on: store) ? Self.watermarkBand : 0)
    }

    private func shuffle() {
        guard viewModel.canTap else { return }
        flight.run(reduceMotion: reduceMotion, reorder: viewModel.shuffleCards, ids: { viewModel.cards.map(\.id) })
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
    let store = StoreManager()
    return ColorSenseView()
        .environmentObject(store)
        .environmentObject(AppFlowCoordinator(store: store))
}
