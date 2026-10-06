//
//  PaywallComparison.swift
//  Magic Tricks
//

import SwiftUI

private let key = L10nDomain("paywall")

enum PaywallMetrics {
    // iPhone SE-sized screens get tighter rows so the table and the pinned dock fit together.
    static let isCompactScreen = UIScreen.main.bounds.height < 700
}

// Free next to Pro: what you have now, what the payment adds.
struct PaywallComparison: View {
    let rows: [PaywallRow]
    let highlighted: TrickType?
    let appeared: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let freeWidth: CGFloat = 54
    private static let proWidth: CGFloat = 66

    var body: some View {
        VStack(spacing: 0) {
            header
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                Rectangle()
                    .fill(Color.cardBorder.opacity(0.6))
                    .frame(height: 1)
                    .padding(.leading, 38)
                PaywallComparisonRow(
                    row: row,
                    isHighlighted: row.trickType != nil && row.trickType == highlighted,
                    pop: reduceMotion || appeared,
                    popDelay: 0.3 + Double(index) * 0.07,
                    animates: !reduceMotion
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TrickPalette.proGradient.opacity(0.13))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(TrickPalette.proGradient, lineWidth: 1.5)
                }
                .frame(width: Self.proWidth + 8)
                .padding(.trailing, 6)
                .padding(.vertical, 5)
        }
        .cardSurface(cornerRadius: 22)
        // Fixed-width columns can't take accessibility sizes; a dense table is capped like system tables are.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Spacer(minLength: 0)
            Text(key("column.free"))
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: Self.freeWidth)
            Text(key("pill"))
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(TrickPalette.proGradient))
                .frame(width: Self.proWidth)
        }
        .padding(.vertical, PaywallMetrics.isCompactScreen ? 4 : 6)
        .accessibilityHidden(true)
    }

    fileprivate static var columnWidths: (free: CGFloat, pro: CGFloat) { (freeWidth, proWidth) }
}

private struct PaywallComparisonRow: View {
    let row: PaywallRow
    let isHighlighted: Bool
    let pop: Bool
    let popDelay: Double
    let animates: Bool

    private var color: Color { row.trickType?.collectionColor ?? TrickPalette.accentPrimary }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.16))
                    .frame(width: 28, height: 28)
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)

            Text(row.title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            freeCell
                .frame(width: PaywallComparison.columnWidths.free)

            proCell
                .frame(width: PaywallComparison.columnWidths.pro)
        }
        .padding(.vertical, PaywallMetrics.isCompactScreen ? 5 : 8)
        .background {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.16))
                    .padding(.horizontal, -4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.title), \(String(localized: row.isFree ? key("a11y.inBoth") : key("a11y.proOnly")))")
    }

    private var symbol: String {
        if case .trick(let trick) = row.kind { trick.image.rawValue } else { "sparkles" }
    }

    @ViewBuilder
    private var freeCell: some View {
        if row.isFree {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)
        } else {
            Image(systemName: "lock.fill")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }

    private var proCell: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 21))
            .foregroundStyle(TrickPalette.accentPrimary)
            .scaleEffect(pop ? 1 : 0.2)
            .opacity(pop ? 1 : 0)
            .animation(animates ? .spring(response: 0.42, dampingFraction: 0.58).delay(popDelay) : nil, value: pop)
    }
}
