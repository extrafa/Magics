import Foundation

extension Instruction {
    static let calculatorPrediction = Instruction(
        title: String(localized: "instruction.calculatorPrediction.title"),
        effect: String(localized: "instruction.calculatorPrediction.effect"),
        secret: String(localized: "instruction.calculatorPrediction.secret"),
        steps: [
            InstructionStep(
                title: String(localized: "instruction.calculatorPrediction.step1.title"),
                description: String(localized: "instruction.calculatorPrediction.step1.description"),
                phase: .preparation,
                actions: [.hapticSettings]
            ),
            InstructionStep(
                title: String(localized: "instruction.calculatorPrediction.step2.title"),
                description: String(localized: "instruction.calculatorPrediction.step2.description"),
                phase: .preparation
            ),
            InstructionStep(
                title: String(localized: "instruction.calculatorPrediction.step3.title"),
                description: String(localized: "instruction.calculatorPrediction.step3.description"),
                phase: .preparation
            ),
            InstructionStep(
                title: String(localized: "instruction.calculatorPrediction.step4.title"),
                description: String(localized: "instruction.calculatorPrediction.step4.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.calculatorPrediction.step5.title"),
                description: String(localized: "instruction.calculatorPrediction.step5.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.calculatorPrediction.step6.title"),
                description: String(localized: "instruction.calculatorPrediction.step6.description"),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: "instruction.calculatorPrediction.step7.title"),
                description: String(localized: "instruction.calculatorPrediction.step7.description"),
                phase: .demonstration
            ),
        ]
    )
}
