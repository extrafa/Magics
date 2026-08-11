//
//  AppSheetView.swift
//  Magic Tricks
//
//  Created by Ross on 11/01/2026.
//

import SwiftUI

struct AppSheetView: View {
    let activeSheet: SheetFlow
    @EnvironmentObject private var flow: AppFlowCoordinator

    var body: some View {
        switch activeSheet {
        case .instruction(let instruction):
            NavigationStack {
                InstructionView(instruction: instruction)
            }
        case .instructionFirstLaunch(let instruction, let trick):
            NavigationStack {
                InstructionView(instruction: instruction) {
                    flow.markTrickAsSeen(trick)
                    flow.activeSheet = nil
                    flow.activeFlow = .trick(trick: trick)
                }
            }
        }
    }
}
