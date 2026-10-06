//
//  PaywallShowcase.swift
//  Magic Tricks
//

import SwiftUI

// A swipeable fan of the tricks' disguises with a live caption and icon switches underneath.
struct PaywallShowcase: View {
    let tricks: [PaywallTrick]

    @State private var index = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // iPhone SE-sized screens: shrink the fan so the caption and switches stay above the pinned dock.
    static let isCompactScreen = UIScreen.main.bounds.height < 700

    private static let base: CGFloat = isCompactScreen ? 0.33 : 0.52
    private static let stageHeight = PaywallDisguiseScreen.designSize.height * base + 14

    private var current: PaywallTrick { tricks[index] }

    var body: some View {
        VStack(spacing: 12) {
            stage
            caption
            switches
        }
        .task(id: index) {
            guard !reduceMotion, tricks.count > 1 else { return }
            try? await Task.sleep(seconds: 4)
            guard !Task.isCancelled else { return }
            select((index + 1) % tricks.count)
        }
    }

    // MARK: Stage

    private var stage: some View {
        ZStack {
            RadialGradient(
                colors: [current.trick.id.collectionColor.opacity(0.4), .clear],
                center: .center,
                startRadius: 0,
                endRadius: Self.stageHeight / 2 - 4
            )
            .frame(maxWidth: .infinity)
            .frame(height: Self.stageHeight + 60)
            .allowsHitTesting(false)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.6), value: index)

            ForEach(tricks.indices, id: \.self) { i in
                let d = relativePosition(of: i)
                PaywallDisguiseScreen(type: tricks[i].id, isActive: i == index)
                    .scaleEffect(Self.base * (d == 0 ? 1 : 0.8))
                    .frame(
                        width: PaywallDisguiseScreen.designSize.width * Self.base,
                        height: PaywallDisguiseScreen.designSize.height * Self.base
                    )
                    .rotationEffect(.degrees(Double(d) * 7))
                    .offset(x: CGFloat(d) * 96, y: abs(CGFloat(d)) * 12)
                    .opacity(abs(d) == 0 ? 1 : abs(d) == 1 ? 0.9 : 0)
                    .zIndex(Double(10 - abs(d)))
                    .onTapGesture { select(i) }
                    .accessibilityHidden(true)
            }
        }
        .frame(height: Self.stageHeight)
        .frame(maxWidth: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20).onEnded { value in
                if value.translation.width < -30 {
                    select((index + 1) % tricks.count)
                } else if value.translation.width > 30 {
                    select((index - 1 + tricks.count) % tricks.count)
                }
            }
        )
    }

    // Signed distance from the selected card, wrapped so the fan loops around.
    private func relativePosition(of i: Int) -> Int {
        let n = tricks.count
        var d = (i - index) % n
        if d > n / 2 { d -= n }
        if d < -(n / 2) { d += n }
        return d
    }

    private func select(_ i: Int) {
        guard i != index else { return }
        withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.82)) {
            index = i
        }
    }

    // MARK: Caption

    private var caption: some View {
        VStack(spacing: 3) {
            Text(current.trick.title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.textPrimary)
            Text(current.effect)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .id(index)
        .transition(.opacity)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: index)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(String(localized: current.trick.title)). \(current.effect)")
    }

    // MARK: Switches

    private var switches: some View {
        HStack(spacing: 10) {
            ForEach(tricks.indices, id: \.self) { i in
                let color = tricks[i].id.collectionColor
                let isSelected = i == index
                Button { select(i) } label: {
                    Image(systemName: tricks[i].trick.image.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(color.opacity(isSelected ? 0.28 : 0.12)))
                        .overlay(Circle().stroke(color, lineWidth: isSelected ? 1.5 : 0))
                        .scaleEffect(isSelected ? 1.08 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: tricks[i].trick.title))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
