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
    
    private let operators: Set<String> = ["+", "−", "×", "÷", "%"]
    private let expressionEvaluator: CalculatorExpressionEvaluating
    private var savedValue: String?
    private var saveBlinkTask: Task<Void, Never>?

    init(expressionEvaluator: CalculatorExpressionEvaluating = CalculatorPredictionEngine()) {
        self.expressionEvaluator = expressionEvaluator
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
            appendOperator("−")
        default:
            appendNum(button.rawValue)
        }
    }
    
    func saveSecretValue() {
        let hasOperator = display.contains { char in
            operators.contains(String(char))
        }
        
        guard !hasOperator else { return }

        savedValue = display
        triggerSaveBlink()
    }
    
    private func appendNum(_ num: String) {
        if display == "0" {
            display = num
        } else {
            display.append(num)
        }
    }
    
    private func appendOperator(_ op: String) {
        guard let last = display.last else { return }
        
        if last == "," { return }
        
        if operators.contains(String(last)) {
            display.removeLast()
        }
        
        display.append(op)
    }
    
    private func appendDecimal() {
        let components = display.split { char in
            operators.contains(String(char))
        }
        
        if let last = components.last, !last.contains(",") {
            display.append(",")
        }
    }
    
    private func delete() {
        if display.count > 1 {
            display.removeLast()
        } else {
            display = "0"
        }
    }
    
    private func calculate() {
        if savedValue != nil {
            showSecretResult()
            return
        }
        
        guard let last = display.last else { return }

        if last == "," { return }

        let lastStr = String(last)
        if lastStr == "%" {
            let base = String(display.dropLast())
            guard !base.isEmpty else { return }
            do {
                let result = try expressionEvaluator.evaluate(base + "/100")
                display = formatResult(result).replacingOccurrences(of: ".", with: ",")
            } catch { }
            return
        }
        if operators.contains(lastStr) { return }
        
        do {
            let result = try expressionEvaluator.evaluate(display)
            let formatted = formatResult(result)
            display = formatted.replacingOccurrences(of: ".", with: ",")
        } catch {
            return
        }
    }
    
    private func formatResult(_ value: Double) -> String {
        guard value.isFinite else { return "Error" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            if let whole = Int(exactly: value) {
                return String(whole)
            }
            return String(format: "%.0f", value)
        }
        return String(value)
    }
    
    private func showSecretResult() {
        guard let savedValue else { return }
        display = savedValue
        self.savedValue = nil
    }

    private func triggerSaveBlink() {
        saveBlinkTask?.cancel()
        saveBlinkTask = Task { [weak self] in
            guard let self else { return }

            for _ in 0..<2 {
                isSaveBlinkVisible = true
                try? await Task.sleep(for: .milliseconds(140))
                isSaveBlinkVisible = false
                try? await Task.sleep(for: .milliseconds(140))
            }
        }
    }
}
