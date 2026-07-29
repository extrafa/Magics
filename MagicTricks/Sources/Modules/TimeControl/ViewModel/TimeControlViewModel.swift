//
//  TimeControlViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 23/08/2025.
//

import Foundation

@MainActor
final class TimeControlViewModel: ObservableObject {
    @Published private(set) var displayedElapsed: TimeInterval = 0
    @Published private(set) var isRunning = false
    @Published private(set) var isTransmitting = false

    private let signalTransmitter: TimeControlSignalTransmitting
    private let hapticEngineManager: HapticEngineManaging
    private var accumulatedElapsed: TimeInterval = 0
    private var startDate: Date?
    private var timerTask: Task<Void, Never>?
    private var transmissionTask: Task<Void, Never>?
    private var transmissionPhase: TimeControlTransmissionPhase?

    init(
        signalTransmitter: TimeControlSignalTransmitting? = nil,
        hapticEngineManager: HapticEngineManaging? = nil
    ) {
        self.signalTransmitter = signalTransmitter ?? TimeControlSignalTransmitter()
        self.hapticEngineManager = hapticEngineManager ?? HapticManager.shared
    }

    var formattedTime: String {
        let totalHundredths: Int
        if isRunning {
            totalHundredths = Int((displayedElapsed * 100).rounded(.down))
        } else {
            totalHundredths = Int((displayedElapsed * 100).rounded())
        }
        let minutes = totalHundredths / 6000
        let seconds = (totalHundredths / 100) % 60
        let hundredths = totalHundredths % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }

    var canReset: Bool {
        !isRunning && displayedElapsed > 0
    }

    var canUsePrimaryAction: Bool {
        !isTransmitting || transmissionPhase == .waitingForStartTrigger
    }

    func handlePrimaryAction() {
        guard canUsePrimaryAction else { return }

        if transmissionPhase == .waitingForStartTrigger {
            cancelTransmission()
        }

        if isRunning {
            stop()
        } else {
            start()
        }
    }

    func reset() {
        guard !isRunning else { return }
        displayedElapsed = 0
        accumulatedElapsed = 0
        startDate = nil
    }

    func handleSceneBecameActive() {
        hapticEngineManager.restartEngineIfNeeded()
    }

    func onDisappear() {
        cancelTransmission()
        stopTimer()
        isRunning = false
        startDate = nil
    }

    private func start() {
        guard !isRunning else { return }
        isRunning = true
        startDate = Date()
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                self.tick()
                try? await Task.sleep(for: .milliseconds(10))
            }
        }
    }

    private func tick() {
        guard isRunning, let startDate else { return }
        displayedElapsed = accumulatedElapsed + Date().timeIntervalSince(startDate)
    }

    private func stop() {
        stopTimer()
        isRunning = false

        let currentElapsed = accumulatedElapsed + (startDate.map { Date().timeIntervalSince($0) } ?? 0)
        let frozenElapsed = floor(currentElapsed * 100) / 100
        let totalHundredths = Int(frozenElapsed * 100)

        accumulatedElapsed = frozenElapsed
        displayedElapsed = frozenElapsed
        startDate = nil

        transmit(second: (totalHundredths / 100) % 60, hundredths: totalHundredths % 100)
    }

    private func transmit(second: Int, hundredths: Int) {
        cancelTransmission()
        transmissionTask = Task { [weak self] in
            guard let self else { return }
            isTransmitting = true
            await signalTransmitter.transmit(
                second: second,
                hundredths: hundredths
            ) { [weak self] phase in
                self?.transmissionPhase = phase
            }
            guard !Task.isCancelled else { return }
            isTransmitting = false
            transmissionPhase = nil
            transmissionTask = nil
        }
    }

    private func cancelTransmission() {
        transmissionTask?.cancel()
        transmissionTask = nil
        signalTransmitter.cancel()
        isTransmitting = false
        transmissionPhase = nil
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}
