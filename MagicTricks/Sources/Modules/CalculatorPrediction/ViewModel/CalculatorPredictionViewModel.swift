//
//  CalculatorPredictionViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 31/01/2026.
//

import Foundation

@MainActor
final class CalculatorPredictionViewModel: ObservableObject {

    @Published var display: String = "0"
    @Published var isSaveBlinkVisible = false

    private static let operators: Set<String> = ["+", "−", "×", "÷", "%"]
    private static let maxResultFractionDigits = 10
    private let expressionEvaluator: CalculatorExpressionEvaluating
    private var savedValue: String?
    private var saveBlinkTask: Task<Void, Never>?

    private lazy var groupingFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private lazy var resultFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = Self.maxResultFractionDigits
        return formatter
    }()

    init(expressionEvaluator: CalculatorExpressionEvaluating = CalculatorPredictionEngine()) {
        self.expressionEvaluator = expressionEvaluator
    }

    private var decimalSeparator: String { Locale.current.decimalSeparator ?? "." }
    private var groupingSeparator: String { Locale.current.groupingSeparator ?? "," }

    private var rawDisplay: String {
        display.replacingOccurrences(of: groupingSeparator, with: "")
    }

    func buttonPressed(_ button: CalculatorPredictionButton) {
        switch button {
        case .clear:
            display = "0"
        case .delete:
            delete()
        case .equal:
            calculate()
        case .add, .subtract, .multiple, .divide, .percent:
            appendOperator(button.rawValue)
        case .decimal:
            appendDecimal()
        case .negative:
            toggleSign()
        default:
            appendNum(button.rawValue)
        }
    }

    func saveSecretValue() {
        let raw = rawDisplay
        let hasOperator = raw.contains { Self.operators.contains(String($0)) }
        guard !hasOperator else { return }
        savedValue = raw
        triggerSaveBlink()
    }

    private func appendNum(_ num: String) {
        let raw = rawDisplay
        guard !raw.hasSuffix("%") else { return }
        let newRaw = raw == "0" ? num : raw + num
        display = formatExpression(newRaw)
    }

    private func appendOperator(_ op: String) {
        var raw = rawDisplay
        guard let last = raw.last else { return }
        if String(last) == decimalSeparator { return }
        if Self.operators.contains(String(last)) { raw.removeLast() }
        raw.append(op)
        display = formatExpression(raw)
    }

    private func toggleSign() {
        var raw = rawDisplay
        guard !raw.isEmpty else { return }
        let lastOperatorIndex = raw.lastIndex { Self.operators.contains(String($0)) }
        let numberStart = lastOperatorIndex.map { raw.index(after: $0) } ?? raw.startIndex
        if raw[numberStart...].hasPrefix("-") {
            raw.remove(at: numberStart)
        } else {
            raw.insert("-", at: numberStart)
        }
        display = formatExpression(raw)
    }

    private func appendDecimal() {
        let raw = rawDisplay
        let components = raw.split { Self.operators.contains(String($0)) }
        if let last = components.last, !last.contains(decimalSeparator) {
            display = formatExpression(raw + decimalSeparator)
        }
    }

    private func delete() {
        let raw = rawDisplay
        if raw.count > 1 {
            display = formatExpression(String(raw.dropLast()))
        } else {
            display = "0"
        }
    }

    private func calculate() {
        if savedValue != nil {
            showSecretResult()
            return
        }

        let raw = rawDisplay
        guard let last = raw.last else { return }
        if String(last) == decimalSeparator { return }

        let lastStr = String(last)
        if lastStr == "%" {
            guard raw.count > 1 else { return }
            do {
                let result = try evaluatePercent(raw)
                display = formatResult(result)
            } catch { }
            return
        }
        if Self.operators.contains(lastStr) { return }

        do {
            let result = try expressionEvaluator.evaluate(raw)
            display = formatResult(result)
        } catch { }
    }

    // "%" isn't evaluable directly: resolved to a number first, as a fraction of the left operand after +/- (no parentheses to group it).
    private func evaluatePercent(_ raw: String) throws -> Double {
        let base = String(raw.dropLast())
        guard !base.isEmpty else { throw CalculatorExpressionError.evaluationFailed }

        guard let opIndex = base.indices.dropFirst().last(where: { Self.operators.contains(String(base[$0])) }) else {
            return try expressionEvaluator.evaluate(base) / 100
        }

        let op = base[opIndex]
        let left = String(base[base.startIndex..<opIndex])
        let right = String(base[base.index(after: opIndex)...])

        switch op {
        case "+", "−":
            let leftValue = try expressionEvaluator.evaluate(left)
            let rightValue = try expressionEvaluator.evaluate(right)
            let percentOfLeft = leftValue * rightValue / 100
            return op == "+" ? leftValue + percentOfLeft : leftValue - percentOfLeft
        default:
            return try expressionEvaluator.evaluate("\(left)\(op)\(right)/100")
        }
    }

    private func formatResult(_ value: Double) -> String {
        guard value.isFinite else { return "Error" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            if let whole = Int(exactly: value) {
                return formatExpression(String(whole))
            }
            return formatExpression(String(format: "%.0f", value))
        }
        let str = resultFormatter.string(from: value as NSNumber) ?? String(value)
        return formatExpression(str)
    }

    private func formatExpression(_ raw: String) -> String {
        var result = ""
        var numBuffer = ""

        for char in raw {
            if Self.operators.contains(String(char)) {
                result += formatNumber(numBuffer) + String(char)
                numBuffer = ""
            } else {
                numBuffer.append(char)
            }
        }
        result += formatNumber(numBuffer)
        return result
    }

    private func formatNumber(_ num: String) -> String {
        guard !num.isEmpty else { return "" }

        let isNegative = num.hasPrefix("-")
        let unsigned = isNegative ? String(num.dropFirst()) : num

        let intPart: String
        let fracPart: String
        if let separatorRange = unsigned.range(of: decimalSeparator) {
            intPart = String(unsigned.prefix(upTo: separatorRange.lowerBound))
            fracPart = String(unsigned.suffix(from: separatorRange.lowerBound))
        } else {
            intPart = unsigned
            fracPart = ""
        }

        return (isNegative ? "-" : "") + groupedDigits(intPart) + fracPart
    }

    private func groupedDigits(_ digits: String) -> String {
        guard let value = Decimal(string: digits) else { return digits }
        return groupingFormatter.string(from: value as NSDecimalNumber) ?? digits
    }

    private func showSecretResult() {
        guard let savedValue else { return }
        display = formatExpression(savedValue)
        self.savedValue = nil
    }

    private func triggerSaveBlink() {
        saveBlinkTask?.cancel()
        saveBlinkTask = Task { [weak self] in
            guard let self else { return }
            for _ in 0..<2 {
                isSaveBlinkVisible = true
                try? await Task.sleep(milliseconds: 140)
                isSaveBlinkVisible = false
                try? await Task.sleep(milliseconds: 140)
            }
        }
    }
}
