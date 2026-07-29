//
//  MagicGalleryCaptureFlow.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

struct MagicGalleryCaptureFlow {
    private(set) var isSequential = false
    private var pendingNumber: Int?

    mutating func startSequential(firstNumber: Int) -> MagicGalleryCaptureSession {
        isSequential = true
        pendingNumber = nil
        return MagicGalleryCaptureSession(number: firstNumber)
    }

    mutating func startSingle(number: Int) -> MagicGalleryCaptureSession {
        isSequential = false
        pendingNumber = nil
        return MagicGalleryCaptureSession(number: number)
    }

    mutating func cancel() {
        isSequential = false
        pendingNumber = nil
    }

    mutating func completeCapture(nextAvailableNumber: Int?) {
        guard isSequential else {
            pendingNumber = nil
            return
        }

        pendingNumber = nextAvailableNumber
        if pendingNumber == nil {
            isSequential = false
        }
    }

    mutating func failCapture() {
        cancel()
    }

    mutating func pendingSessionIfNeeded(isActiveSessionPresent: Bool) -> MagicGalleryCaptureSession? {
        guard isSequential, !isActiveSessionPresent, let pendingNumber else { return nil }
        self.pendingNumber = nil
        return MagicGalleryCaptureSession(number: pendingNumber)
    }
}

