//
//  MindPatternViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 17/04/2026.
//

import Foundation

@MainActor
final class MindPatternViewModel: ObservableObject {

    private enum TapOutcome {
        case accepted
        case readyToTransmit([MindPatternAnimal])
    }

    private enum Phase {
        case spectatorInput
        case transmitting
        case completed
    }

    let tiles: [MindPatternTile]
    private var phase: Phase = .spectatorInput
    @Published private(set) var spectatorSelection: [MindPatternAnimal] = []
    @Published private(set) var isTransmitting = false
    @Published private(set) var activeTapAnimal: MindPatternAnimal?

    private let signalTransmitter: MindPatternSignalTransmitting
    private var transmissionTask: Task<Void, Never>?
    private var tapAnimationTask: Task<Void, Never>?

    init(
        tiles: [MindPatternTile] = defaultMindPatternTiles,
        signalTransmitter: MindPatternSignalTransmitting? = nil
    ) {
        self.tiles = tiles
        self.signalTransmitter = signalTransmitter ?? MindPatternSignalTransmitter()
    }

    func handleTap(on tile: MindPatternTile) {
        animateTap(for: tile.animal)

        if isTransmitting {
            signalTransmitter.performerTapped()
            return
        }

        switch phase {
        case .spectatorInput:
            switch handleSpectatorTap(on: tile) {
            case .accepted:
                break
            case .readyToTransmit(let animals):
                transmit(animals)
            }
        case .transmitting, .completed:
            break
        }
    }

    func reset() {
        cancelTasks()
        activeTapAnimal = nil
        phase = .spectatorInput
        spectatorSelection.removeAll()
    }

    func cancelTasks() {
        cancelTransmission()
        tapAnimationTask?.cancel()
        tapAnimationTask = nil
    }

    private func completeTransmission() {
        guard phase == .transmitting else { return }
        phase = .completed
    }

    private func animateTap(for animal: MindPatternAnimal) {
        guard activeTapAnimal != animal else { return }
        tapAnimationTask?.cancel()
        activeTapAnimal = animal
        tapAnimationTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(140))
            guard let self, !Task.isCancelled, activeTapAnimal == animal else { return }
            activeTapAnimal = nil
            tapAnimationTask = nil
        }
    }

    private func transmit(_ animals: [MindPatternAnimal]) {
        cancelTransmission()
        transmissionTask = Task { [weak self] in
            guard let self else { return }
            isTransmitting = true
            await signalTransmitter.transmit(animals)
            guard !Task.isCancelled else { return }
            isTransmitting = false
            transmissionTask = nil
            completeTransmission()
        }
    }

    private func cancelTransmission() {
        transmissionTask?.cancel()
        transmissionTask = nil
        signalTransmitter.cancel()
        isTransmitting = false
    }

    private func handleSpectatorTap(on tile: MindPatternTile) -> TapOutcome {
        if spectatorSelection.contains(tile.animal) {
            return .accepted
        }

        spectatorSelection.append(tile.animal)

        if spectatorSelection.count == tiles.count {
            phase = .transmitting
            return .readyToTransmit(spectatorSelection)
        }

        return .accepted
    }
}
