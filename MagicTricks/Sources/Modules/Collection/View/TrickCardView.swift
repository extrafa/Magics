//
//  TrickCardView.swift
//  Magic Tricks
//
//  Created by Ross on 10/04/2026.
//

import SwiftUI

struct TrickCardView: View {

    let trick: Trick
    let isLocked: Bool
    let onStartTap: () -> Void
    let onHowToTap: () -> Void

    // Seeded close to a typical badge width so the first frame (before GeometryReader
    // reports the real measurement) doesn't render the title with zero trailing space.
    @State private var badgeWidth: CGFloat = 94

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardBody
                .grayscale(isLocked ? 1.0 : 0)
                .opacity(isLocked ? 0.52 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isLocked)
                .overlay {
                    if isLocked {
                        // A real Button, not a bare tap gesture, so VoiceOver gets one whole-card activation target.
                        Button(action: onStartTap) {
                            Color.clear
                                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            String(format: String(localized: "collection.locked.accessibilityLabel"), String(localized: trick.title))
                        )
                    }
                }

            badge
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(key: BadgeWidthPreferenceKey.self, value: geometry.size.width)
                    }
                }
                .padding(.top, 16)
                .padding(.trailing, 16)
        }
        .onPreferenceChange(BadgeWidthPreferenceKey.self) { badgeWidth = $0 }
        // Caps growth so the icon/title/badge row stays usable at the largest accessibility sizes.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // MARK: Card

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer(minLength: 16)
            TrickCardActions(trickName: String(localized: trick.title), onStartTap: onStartTap, onHowToTap: onHowToTap)
                // The locked overlay above exposes one combined element - avoid duplicate "Start"/"Learn" VoiceOver targets.
                .accessibilityHidden(isLocked)
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 208, alignment: .topLeading)
        .cardSurface(cornerRadius: 22)
        .shadow(color: Color.black.opacity(isLocked ? 0.03 : 0.06), radius: 18, x: 0, y: 8)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            TrickIcon(
                systemName: trick.image.rawValue,
                color: trick.id.collectionColor,
                size: CGSize(width: 54, height: 54)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(trick.cardTitle ?? trick.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    // The badge floats independently in a ZStack overlay, inset less from the card edge
                    // than this content area - reserve exactly the width it measured, so it never overlaps
                    // regardless of locale/badge text length.
                    .padding(.trailing, max(0, badgeWidth - 6))

                Text(trick.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)
        }
    }

    // MARK: Badge

    @ViewBuilder
    private var badge: some View {
        if isLocked {
            proBadge
        } else {
            TrickDifficultyBadge(difficulty: trick.difficulty)
        }
    }

    private var proBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9, weight: .bold))
                .accessibilityHidden(true)
            Text(String(localized: "trick.proBadge"))
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .tracking(0.4)
        }
        .foregroundStyle(Color.primary.opacity(0.45))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.07)))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.primary.opacity(0.22), lineWidth: 1.2)
        }
    }
}

private struct BadgeWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    VStack(spacing: 16) {
        TrickCardView(
            trick: TrickCollection.tricks[0],
            isLocked: false,
            onStartTap: {},
            onHowToTap: {}
        )
        TrickCardView(
            trick: TrickCollection.tricks[1],
            isLocked: true,
            onStartTap: {},
            onHowToTap: {}
        )
    }
    .padding()
}
