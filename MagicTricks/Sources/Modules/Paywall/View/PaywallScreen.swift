//
//  PaywallScreen.swift
//  Magic Tricks
//

import SwiftUI

struct PaywallScreen: View {
    let onDismiss: Completion

    @EnvironmentObject private var store: StoreManager
    @State private var storeAlert: StoreAlert?
    private static let sidePadding: CGFloat = 24

    private let content: PaywallContent

    init(context: PaywallContext = .general, onDismiss: @escaping Completion) {
        self.content = PaywallContent(context: context)
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            PaywallCardFan(cards: content.cards, cardWidth: Self.cardWidth(in: geo.size, hasFocus: content.focus != nil))
                            text
                        }
                        .padding(.horizontal, Self.sidePadding)
                        .padding(.vertical, 8)
                        // Centers the hand and the text on tall screens; at big text sizes it grows and scrolls instead.
                        .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .leading)
                    }
                    .scrollBouncesOnlyWhenNeeded()
                }

                PaywallPurchaseDock(storeAlert: $storeAlert)
            }
            .background { Color.backgroundScreen.ignoresSafeArea() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
        }
        .task {
            // Already owns it (a reinstall, say): nothing to sell, and no change will arrive to close this screen.
            if store.hasProAccess {
                onDismiss()
                return
            }
            await store.reloadProductsIfNeeded()
        }
        .onChange(of: store.hasProAccess) { _ in
            if store.hasProAccess { onDismiss() }
        }
        .tint(.primary)
        .storeErrorAlert($storeAlert)
    }

    // MARK: Close

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background {
                    if #available(iOS 26, *) {
                        Color.clear
                    } else {
                        Circle().fill(Color.primary.opacity(0.08))
                    }
                }
        }
        .accessibilityLabel(String(localized: "common.close"))
    }

    // MARK: Text

    // Wide screens get bigger cards; short ones (SE) shrink them so the text and the dock still fit.
    // The contextual paywall has one more line (what the trick does), so its cards give some room back.
    private static func cardWidth(in size: CGSize, hasFocus: Bool) -> CGFloat {
        min(size.width * (hasFocus ? 0.22 : 0.32), size.height * 0.19, 150)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(content.headline)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let effect = content.effect {
                Text(effect)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.textPrimary)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(content.rows, id: \.title) { row in
                    rowView(row)
                }
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }

    // One line of the deal: an icon, what it is in two or three words, then the detail.
    private func rowView(_ row: PaywallContent.Row) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.symbol)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.textPrimary.opacity(0.85))
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.textPrimary)
                Text(coloredNames(in: row.text))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // Each trick name takes the colour of its card, so the sentence reads as the hand above it.
    private func coloredNames(in sentence: String) -> AttributedString {
        // Non-breaking spaces keep a name on one line: the sentence wraps between tricks, never inside one.
        var glued = sentence
        for trick in content.cards {
            let name = String(localized: trick.title)
            glued = glued.replacingOccurrences(of: name, with: name.replacingOccurrences(of: " ", with: "\u{00A0}"))
        }
        var result = AttributedString(glued)
        for trick in content.cards {
            let name = String(localized: trick.title).replacingOccurrences(of: " ", with: "\u{00A0}")
            if let range = result.range(of: name) {
                result[range].foregroundColor = trick.id.textColor
            }
        }
        return result
    }
}

extension View {
    @ViewBuilder
    func scrollBouncesOnlyWhenNeeded() -> some View {
        if #available(iOS 16.4, *) {
            scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }
}
