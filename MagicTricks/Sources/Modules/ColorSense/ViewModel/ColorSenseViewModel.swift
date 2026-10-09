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
