//
//  PaywallCoinTrail.swift
//  Magic Tricks
//

import SwiftUI

private let key = L10nDomain("paywall")

// One filled coin, then empty ones fading out: you pay today, and that is the last payment.
struct PaywallCoinTrail: View {
    private static let emptyCoins = 6
    private static let coinSize: CGFloat = 40

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                paidCoin
                ForEach(0..<Self.emptyCoins, id: \.self) { index in
                    emptyCoin(opacity: 0.55 - Double(index) * 0.08)
                }
                Image(systemName: "infinity")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: Self.coinSize)
                    .accessibilityHidden(true)
            }

            HStack(alignment: .top, spacing: 12) {
                Text(key("trail.start"))
                Spacer(minLength: 0)
                Text(key("trail.end"))
                    .multilineTextAlignment(.trailing)
            }
            .font(.system(.footnote, design: .rounded, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var paidCoin: some View {
        Circle()
            .fill(TrickPalette.proGradient)
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: Color(red: 1.0, green: 0.4, blue: 0.25).opacity(0.45), radius: 14, y: 4)
            .frame(maxWidth: Self.coinSize)
            .aspectRatio(1, contentMode: .fit)
    }

    private func emptyCoin(opacity: Double) -> some View {
        Circle()
            .strokeBorder(Color.textPrimary.opacity(opacity), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            .frame(maxWidth: Self.coinSize)
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)
    }
}

#Preview {
    PaywallCoinTrail()
        .padding(24)
        .background(Color.backgroundScreen)
}
