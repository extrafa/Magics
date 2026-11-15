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
                    .sheetCloseToolbar()
            }
        case .instructionFirstLaunch(let instruction, let trick):
            NavigationStack {
                InstructionView(instruction: instruction) {
                    flow.startTrickAfterInstruction(trick)
                }
                .sheetCloseToolbar()
            }
        case .rateApp:
            RateAppSheet()
                .environmentObject(flow)
        }
    }
}

// A close button at the top left of a sheet that has its own navigation bar.
private struct SheetCloseToolbar: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.textPrimary)
                }
                .accessibilityLabel(String(localized: "common.close"))
            }
        }
    }
}

extension View {
    func sheetCloseToolbar() -> some View {
        modifier(SheetCloseToolbar())
    }
}
