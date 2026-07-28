import Foundation

protocol CalculatorExpressionEvaluating {
    func evaluate(_ expression: String) throws -> Double
}

enum CalculatorExpressionError: Error {
    case evaluationFailed
}

final class CalculatorPredictionEngine: CalculatorExpressionEvaluating {
    func evaluate(_ expression: String) throws -> Double {
        // Normalize custom operators to NSExpression-compatible syntax
        let normalized = expression
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: ",", with: ".")

        let expr = NSExpression(format: normalized)
        guard let result = expr.expressionValue(with: nil, context: nil) as? NSNumber else {
            throw CalculatorExpressionError.evaluationFailed
        }
        return result.doubleValue
    }
}
