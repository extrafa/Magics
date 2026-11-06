//
//  DelayedActionScheduling.swift
//  Magic Tricks
//

import Foundation

protocol DelayedActionScheduling {
    func schedule(after delay: TimeInterval, action: @escaping Completion)
}

struct DispatchQueueScheduler: DelayedActionScheduling {
    func schedule(after delay: TimeInterval, action: @escaping Completion) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
    }
}
