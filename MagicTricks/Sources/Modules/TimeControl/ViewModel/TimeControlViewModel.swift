//
//  TimeControlViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 23/08/2025.
//

import Foundation

@MainActor
final class TimeControlViewModel: ObservableObject {
    @Published private(set) var displayedHundredths = 0
    @Published private(set) var isRunning = false
    @Published private(set) var isTransmitting = false

    private static let tickIntervalMilliseconds = 16 // matches the display's refresh rate

    private let signalTransmitter: TimeControlSignalTransmitting
    private let hapticEngineManager: HapticEngineManaging
    private var accumulatedElapsed: TimeInterval = 0
    private var startDate: Date?
    private var timerTask: Task<Void, Never>?
    private var transmissionTask: Task<Void, Never>?
    @Published private var transmissionPhase: TimeControlTransmissionPhase?

    init(
        signalTransmitter: TimeControlSignalTransmitting? = nil,
        hapticEngineManager: HapticEngineManaging? = nil
    ) {
        self.signalTransmitter = signalTransmitter ?? TimeControlSignalTransmitter()
        self.hapticEngineManager = hapticEngineManager ?? HapticManager.shared
    }

    var formattedTime: String {
        let minutes = displayedHundredths / 6000
        let seconds = (displayedHundredths / 100) % 60
        let hundredths = displayedHundredths % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }

    var canReset: Bool {
        !isRunning && displayedHundredths > 0
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
        displayedHundredths = 0
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
                try? await Task.sleep(milliseconds: Self.tickIntervalMilliseconds)
            }
        }
    }

    private func tick() {
        guard isRunning, let startDate else { return }
        let elapsed = accumulatedElapsed + Date().timeIntervalSince(startDate)
        let hundredths = Int((elapsed * 100).rounded(.down))
        guard hundredths != displayedHundredths else { return }
        displayedHundredths = hundredths
    }

    private func stop() {
        stopTimer()
        isRunning = false

        let currentElapsed = accumulatedElapsed + (startDate.map { Date().timeIntervalSince($0) } ?? 0)
        let totalHundredths = Int((currentElapsed * 100).rounded(.down))

        accumulatedElapsed = TimeInterval(totalHundredths) / 100
        displayedHundredths = totalHundredths
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
