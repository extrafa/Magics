//
//  PaywallPulseLine.swift
//  Magic Tricks
//

import SwiftUI

private let key = L10nDomain("paywall")

// One pulse, then a flat line that runs off the screen edge: you pay today, and that's all, forever.
// The same signal the tricks use (vibration pulses), drawn instead of felt.
struct PaywallPulseLine: View {
    private static let height: CGFloat = 64
    private static let lineWidth: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                PulseShape(spikeOnly: false)
                    .stroke(Color.textPrimary.opacity(0.28), style: strokeStyle)
                PulseShape(spikeOnly: true)
                    .stroke(TrickPalette.proGradient, style: strokeStyle)
            }
            .frame(height: Self.height)

            Text(key("pulse.label"))
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
        // Decorative: the price caption already says it in words.
        .accessibilityHidden(true)
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round, lineJoin: .round)
    }
}

private struct PulseShape: Shape {
    let spikeOnly: Bool

    private let lead: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        let mid = rect.midY
        let inset = Self.inset
        var path = Path()
        if spikeOnly {
            path.move(to: CGPoint(x: lead, y: mid))
        } else {
            path.move(to: CGPoint(x: 0, y: mid))
            path.addLine(to: CGPoint(x: lead, y: mid))
        }
        path.addLine(to: CGPoint(x: lead + 10, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: lead + 23, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: lead + 33, y: mid))
        if !spikeOnly {
            path.addLine(to: CGPoint(x: rect.maxX, y: mid))
        }
        return path
    }

    private static let inset: CGFloat = 3
}

#Preview {
    PaywallPulseLine()
        .padding(.leading, 24)
        .background(Color.backgroundScreen)
}
