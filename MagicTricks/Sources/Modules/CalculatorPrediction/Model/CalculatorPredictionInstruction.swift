import Foundation

private let key = L10nDomain("instruction.calculatorPrediction")
private let stepImage = KeyDomain("step.calculator")

extension Instruction {
    static let calculatorPrediction = Instruction(
        trickType: .calculatorPrediction,
        title: String(localized: key("title")),
        effect: String(localized: key("effect")),
        secret: String(localized: key("secret")),
        steps: [
            InstructionStep(
                title: String(localized: key("step1.title")),
                description: String(localized: key("step1.description")),
                phase: .preparation,
                imageName: stepImage("acNumber")
            ),
            InstructionStep(
                title: String(localized: key("step2.title")),
                description: String(localized: key("step2.description")),
                phase: .preparation
            ),
            InstructionStep(
                title: String(localized: key("step3.title")),
                description: String(localized: key("step3.description")),
                phase: .preparation
            ),
            InstructionStep(
                title: String(localized: key("step4.title")),
                description: String(localized: key("step4.description")),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: key("step5.title")),
                description: String(localized: key("step5.description")),
                phase: .demonstration
            ),
            InstructionStep(
                title: String(localized: key("step6.title")),
                description: String(localized: key("step6.description")),
                phase: .demonstration,
                imageName: stepImage("multiply")
            ),
            InstructionStep(
                title: String(localized: key("step7.title")),
                description: String(localized: key("step7.description")),
                phase: .demonstration
            ),
        ]
    )
}
