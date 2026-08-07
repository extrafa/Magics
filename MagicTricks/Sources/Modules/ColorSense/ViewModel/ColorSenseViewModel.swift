//
//  ColorSenseViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 05/06/2026.
//

import Foundation

@MainActor
final class ColorSenseViewModel: ObservableObject {
    @Published private(set) var canTap = true
    @Published private(set) var activeTapCardID: UUID?

    let cards: [ColorCard] = [
        .init(colorType: .red,    title: String(localized: "colorMentalism.card.tap")),
        .init(colorType: .yellow, title: String(localized: "colorMentalism.card.trust")),
        .init(colorType: .green,  title: String(localized: "colorMentalism.card.pickOne")),
        .init(colorType: .blue,   title: String(localized: "colorMentalism.card.goOn")),
        .init(colorType: .yellow, title: String(localized: "colorMentalism.card.choose")),
        .init(colorType: .green,  title: String(localized: "colorMentalism.card.feelIt")),
        .init(colorType: .red,    title: String(localized: "colorMentalism.card.notice")),
        .init(colorType: .blue,   title: String(localized: "colorMentalism.card.tap")),
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
        activeTapCardID = nil
        canTap = true
    }

    private func animateTap(for cardID: UUID) {
        tapAnimationTask?.cancel()
        activeTapCardID = cardID
        tapAnimationTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(145))
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
            // delay so the haptic isn't felt right after tap — spectator shouldn't notice it start
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled, let self else { return }
            haptics.playColorCode(type.vibrations) { [weak self] in
                self?.canTap = true
            }
        }
    }
}
