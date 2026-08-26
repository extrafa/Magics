//
//  HapticEnginePlayer.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import CoreHaptics
import Foundation

@MainActor
final class HapticEnginePlayer {
    private enum HapticPlaybackError: Error {
        case engineUnavailable
    }

    private var engine: CHHapticEngine?
    private var currentPlayer: CHHapticPatternPlayer?
    private var supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    init() {
        configureEngine()
    }

    func restartEngineIfNeeded() {
        guard supportsHaptics else { return }

        if engine == nil {
            configureEngine()
            return
        }

        do {
            try engine?.start()
        } catch {
            engine = nil
            configureEngine()
        }
    }

    func playEvents(_ events: [CHHapticEvent], fallback: () -> Void) {
        guard supportsHaptics else {
            fallback()
            return
        }

        do {
            try playEvents(events)
        } catch {
            fallback()
        }
    }

    func stop() {
        guard let engine, let currentPlayer else { return }
        try? currentPlayer.stop(atTime: engine.currentTime)
        self.currentPlayer = nil
    }

    private func configureEngine() {
        guard supportsHaptics else { return }

        do {
            let engine = try CHHapticEngine()
            engine.stoppedHandler = { [weak self] _ in
                Task { @MainActor in
                    self?.engine = nil
                }
            }
            engine.resetHandler = { [weak self] in
                Task { @MainActor in
                    self?.engine = nil
                    self?.restartEngineIfNeeded()
                }
            }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    private func playEvents(_ events: [CHHapticEvent]) throws {
        restartEngineIfNeeded()

        guard let engine else {
            throw HapticPlaybackError.engineUnavailable
        }

        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine.makePlayer(with: pattern)
        try player.start(atTime: 0)
        currentPlayer = player
    }
}

extension HapticEnginePlayer: HapticEnginePlaying {}
