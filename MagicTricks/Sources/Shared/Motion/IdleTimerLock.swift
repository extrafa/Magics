//
//  IdleTimerLock.swift
//  Magic Tricks
//

import SwiftUI
import UIKit

// Ref-counted so more than one screen can hold it at once.
@MainActor
enum IdleTimerLock {
    private static var holderCount = 0

    static func acquire() {
        holderCount += 1
        UIApplication.shared.isIdleTimerDisabled = true
    }

    static func release() {
        guard holderCount > 0 else { return }
        holderCount -= 1
        UIApplication.shared.isIdleTimerDisabled = holderCount > 0
    }
}

extension View {
    // Holds the lock for as long as this view is on screen.
    func keepsScreenAwake() -> some View {
        modifier(IdleTimerLockModifier())
    }

    // Holds the lock only while `condition` is true.
    func keepsScreenAwake(while condition: Bool) -> some View {
        modifier(ConditionalIdleTimerLockModifier(condition: condition))
    }
}

private struct IdleTimerLockModifier: ViewModifier {
    @State private var isHolding = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !isHolding else { return }
                isHolding = true
                IdleTimerLock.acquire()
            }
            .onDisappear {
                guard isHolding else { return }
                isHolding = false
                IdleTimerLock.release()
            }
    }
}

private struct ConditionalIdleTimerLockModifier: ViewModifier {
    let condition: Bool
    @State private var isHolding = false

    func body(content: Content) -> some View {
        content
            .onAppear { sync(condition) }
            .onChange(of: condition) { newValue in sync(newValue) }
            .onDisappear { sync(false) }
    }

    private func sync(_ shouldHold: Bool) {
        if shouldHold, !isHolding {
            isHolding = true
            IdleTimerLock.acquire()
        } else if !shouldHold, isHolding {
            isHolding = false
            IdleTimerLock.release()
        }
    }
}
