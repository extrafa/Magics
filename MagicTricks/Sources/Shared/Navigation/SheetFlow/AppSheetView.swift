//
//  AppSheetView.swift
//  Magic Tricks
//
//  Created by Ross on 11/01/2026.
//

import SwiftUI

struct AppSheetView: View {
    let activeSheet: SheetFlow

    var body: some View {
        switch activeSheet {
        case .instruction(let instruction):
            NavigationStack {
                InstructionView(instruction: instruction)
            }
        }
    }
}
