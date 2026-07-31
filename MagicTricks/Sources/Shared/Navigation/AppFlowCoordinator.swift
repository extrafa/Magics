//
//  AppFlowCoordinator.swift
//  Magic Tricks
//
//  Created by Ross on 11/01/2026.
//

import Foundation

@MainActor
final class AppFlowCoordinator: ObservableObject {

    @Published var activeFlow: FullScreenFlow?
    @Published var activeSheet: SheetFlow?

    func open(trick: Trick) {
        activeFlow = .trick(trick: trick)
    }

    func open(instruction: Instruction) {
        activeSheet = .instruction(instruction: instruction)
    }

    func openPaywall() {
        activeFlow = .paywall
    }
}
