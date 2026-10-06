//
//  PaywallCardFan.swift
//  Magic Tricks
//

import SwiftUI

// A hand of playing cards, one per Pro trick: dealt face down, then turned over one by one.
// The whole paywall's single motion; with Reduce Motion the hand simply starts face up.
struct PaywallCardFan: View {
    let cards: [Trick]
    let cardWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spread: Bool
    @State private var faceUp: Bool

    private static let aspect: CGFloat = 1.45
    private static let firstAngle: Double = -14
    private static let step: Double = 13

    init(cards: [Trick], cardWidth: CGFloat) {
        self.cards = cards
        self.cardWidth = cardWidth
        // Start from the end state when nothing will animate, so there is no flash of face-down cards.
        let reduce = UIAccessibility.isReduceMotionEnabled
        _spread = State(initialValue: reduce)
        _faceUp = State(initialValue: reduce)
    }

    private var cardHeight: CGFloat { cardWidth * Self.aspect }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, trick in
                PaywallPlayingCard(
                    trick: trick,
                    angle: faceUp ? 180 : 0
                )
                .frame(width: cardWidth, height: cardHeight)
                .animation(reduceMotion ? nil : flipAnimation(for: index), value: faceUp)
                .rotationEffect(.degrees(spread ? angle(of: index) : 0), anchor: .bottom)
                .animation(reduceMotion ? nil : spreadAnimation(for: index), value: spread)
                .offset(x: pivotX - cardWidth / 2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .bottomLeading)
        // The outermost card swings its lower corner below the pivot line.
        .padding(.bottom, cardWidth * 0.35)
        .accessibilityHidden(true)
        .task {
            guard !reduceMotion else { return }
            // Let the cover finish presenting before the hand is dealt.
            try? await Task.sleep(milliseconds: 250)
            spread = true
            try? await Task.sleep(milliseconds: 650)
            faceUp = true
        }
    }

    // The hand leans right: the pivot sits left of centre and the cards open to the right.
    private var pivotX: CGFloat { cardWidth * 0.9 }

    private func angle(of index: Int) -> Double {
        Self.firstAngle + Self.step * Double(index)
    }

    private func spreadAnimation(for index: Int) -> Animation {
        .spring(response: 0.5, dampingFraction: 0.78).delay(0.04 * Double(index))
    }

    private func flipAnimation(for index: Int) -> Animation {
        .easeInOut(duration: 0.45).delay(0.11 * Double(index))
    }
}

// MARK: - Card

// angle 0 shows the back, 180 the face. It's Animatable so the side can swap exactly at the edge-on moment.
private struct PaywallPlayingCard: View, Animatable {
    let trick: Trick
    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        ZStack {
            if angle < 90 {
                PaywallCardBack()
            } else {
                PaywallCardFace(trick: trick)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
    }
}

private enum CardMetrics {
    static let corner: CGFloat = 14
}

private struct PaywallCardFace: View {
    let trick: Trick

    var body: some View {
        let color = trick.id.collectionColor
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: CardMetrics.corner, style: .continuous)
                .fill(Color.white)
                .overlay {
                    RoundedRectangle(cornerRadius: CardMetrics.corner, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                }
                .overlay {
                    Image(systemName: trick.image.rawValue)
                        .font(.system(size: geo.size.width * 0.46, weight: .semibold))
                        .foregroundStyle(color)
                }
                .overlay(alignment: .topLeading) { pip(color: color, width: geo.size.width) }
                .overlay(alignment: .bottomTrailing) {
                    pip(color: color, width: geo.size.width).rotationEffect(.degrees(180))
                }
        }
        .shadow(color: .black.opacity(0.14), radius: 5, x: -2, y: 1)
    }

    private func pip(color: Color, width: CGFloat) -> some View {
        Image(systemName: trick.image.rawValue)
            .font(.system(size: width * 0.2, weight: .bold))
            .foregroundStyle(color)
            .padding(width * 0.09)
    }
}

private struct PaywallCardBack: View {
    // The app icon's purple, so the deck reads as the app's own.
    private static let violet = Color(red: 0.48, green: 0.18, blue: 0.88)
    private static let magenta = Color(red: 0.69, green: 0.19, blue: 0.69)
    private static let gold = Color(red: 1.0, green: 0.71, blue: 0.18)

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: CardMetrics.corner, style: .continuous)
                .fill(LinearGradient(colors: [Self.violet, Self.magenta], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: CardMetrics.corner - 5, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5)
                        .padding(6)
                }
                .overlay {
                    Image(systemName: "sparkle")
                        .font(.system(size: geo.size.width * 0.4, weight: .regular))
                        .foregroundStyle(Self.gold)
                }
        }
        .shadow(color: .black.opacity(0.14), radius: 5, x: -2, y: 1)
    }
}
