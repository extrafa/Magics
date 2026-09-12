//
//  MagicGalleryCaptureFlow.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import UIKit

struct MagicGalleryCaptureFlow {
    private(set) var isSequential = false
    private var pendingNumber: Int?
    private var sequentialSourceType: UIImagePickerController.SourceType = .camera

    mutating func startSequential(firstNumber: Int, sourceType: UIImagePickerController.SourceType) -> MagicGalleryCaptureSession {
        isSequential = true
        pendingNumber = nil
        sequentialSourceType = sourceType
        return MagicGalleryCaptureSession(number: firstNumber, sourceType: sourceType)
    }

    mutating func startSingle(number: Int, sourceType: UIImagePickerController.SourceType) -> MagicGalleryCaptureSession {
        isSequential = false
        pendingNumber = nil
        return MagicGalleryCaptureSession(number: number, sourceType: sourceType)
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
        return MagicGalleryCaptureSession(number: pendingNumber, sourceType: sequentialSourceType)
    }
}

