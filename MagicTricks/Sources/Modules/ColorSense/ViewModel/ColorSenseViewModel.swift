//
//  ColorSenseViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 05/06/2026.
//

import Foundation

private let key = L10nDomain("colorMentalism.card")

@MainActor
final class ColorSenseViewModel: ObservableObject {
    @Published private(set) var canTap = true
    @Published private(set) var activeTapCardID: UUID?

    let cards: [ColorCard] = [
        .init(colorType: .red,    title: String(localized: key("tap")),      height: 150, rotation: -2),
        .init(colorType: .yellow, title: String(localized: key("trust")),    height: 180, rotation:  2),
        .init(colorType: .green,  title: String(localized: key("pickOne")),  height: 165, rotation: -1),
        .init(colorType: .blue,   title: String(localized: key("goOn")),     height: 175, rotation:  1),
        .init(colorType: .yellow, title: String(localized: key("choose")),   height: 145, rotation: -2),
        .init(colorType: .green,  title: String(localized: key("feelIt")),   height: 190, rotation:  2),
        .init(colorType: .red,    title: String(localized: key("notice")),   height: 160, rotation:  1),
        .init(colorType: .blue,   title: String(localized: key("tap")),      height: 180, rotation: -1),
    ]

    // Gap between cards, both ways: the two columns are filled row by row.
    static let gridSpacing: CGFloat = 14
    private static let columnCount = 2

    // The cards' natural height: each row is as tall as its tallest card.
    var gridHeight: CGFloat {
        let rows = stride(from: 0, to: cards.count, by: Self.columnCount).map { start in
            cards[start..<min(start + Self.columnCount, cards.count)].map(\.height).max() ?? 0
        }
        return rows.reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * Self.gridSpacing
    }

    // Shrinks the cards on a short screen (SE, mini) so the whole grid is on it; never grows them.
    func heightScale(forAvailableHeight height: CGFloat) -> CGFloat {
        guard height > 0, gridHeight > 0 else { return 1 }
        return min(1, height / gridHeight)
    }

    private let haptics: CountHapticPlaying
    private var tapAnimationTask: Task<Void, Never>?
    private var playSignalTask: Task<Void, Never>?

    init(haptics: CountHapticPlaying) {
        self.haptics = haptics
    }

    func handleTap(on card: ColorCard) {
        guard canTap else { return }
        animateTap(for: card.id)
        playSignal(for: card.colorType)
    }

    func cancel() {
        tapAnimationTask?.cancel()
        playSignalTask?.cancel()
        haptics.cancelPendingHaptics()
        activeTapCardID = nil
        canTap = true
    }

    private func animateTap(for cardID: UUID) {
        tapAnimationTask?.cancel()
        activeTapCardID = cardID
        tapAnimationTask = Task { [weak self] in
            try? await Task.sleep(milliseconds: 145)
            guard !Task.isCancelled else { return }
            if self?.activeTapCardID == cardID {
                self?.activeTapCardID = nil
            }
        }
    }

    private func playSignal(for type: ColorCardType) {
        canTap = false
        playSignalTask?.cancel()
        playSignalTask = Task { [weak self] in
            try? await Task.sleep(seconds: 1)
            guard !Task.isCancelled, let self else { return }
            haptics.playCount(type.vibrations) { [weak self] in
                self?.canTap = true
            }
        }
    }
}
