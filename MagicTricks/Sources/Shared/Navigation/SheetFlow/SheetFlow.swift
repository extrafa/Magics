import Foundation

enum SheetFlow: Identifiable, Equatable {
    case instruction(instruction: Instruction)

    var id: String {
        switch self {
        case .instruction(let instruction):
            return "instruction_\(instruction.title)"
        }
    }
}
