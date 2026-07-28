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
