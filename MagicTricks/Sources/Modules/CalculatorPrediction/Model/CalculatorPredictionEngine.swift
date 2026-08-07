import Foundation

protocol CalculatorExpressionEvaluating {
    func evaluate(_ expression: String) throws -> Double
}

enum CalculatorExpressionError: Error {
    case evaluationFailed
}

// Recursive descent parser for infix arithmetic expressions.
//
// Grammar:
//   expr   = term   (('+' | '-') term)*
//   term   = factor (('*' | '/' | '%') factor)*
//   factor = ('+' | '-') factor | number
//
// Operator precedence is encoded in the grammar: * / % bind tighter than + -.
// % between two numbers means modulo (e.g. 10%3 = 1).
// Trailing % is handled by the ViewModel before calling evaluate.

final class CalculatorPredictionEngine: CalculatorExpressionEvaluating {

    func evaluate(_ expression: String) throws -> Double {
        let normalized = expression
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: ",", with: ".")

        var parser = try Parser(input: normalized)
        let result = try parser.parseExpr()
        guard parser.isAtEnd else { throw CalculatorExpressionError.evaluationFailed }
        return result
    }
}

// MARK: - Tokenizer

private enum Token: Equatable {
    case number(Double)
    case plus, minus, multiply, divide, modulo
}

private func tokenize(_ input: String) throws -> [Token] {
    var tokens: [Token] = []
    var i = input.startIndex

    while i < input.endIndex {
        let ch = input[i]
        switch ch {
        case "0"..."9", ".":
            var raw = ""
            while i < input.endIndex && (input[i].isNumber || input[i] == ".") {
                raw.append(input[i])
                i = input.index(after: i)
            }
            guard let value = Double(raw) else { throw CalculatorExpressionError.evaluationFailed }
            tokens.append(.number(value))
        case "+": tokens.append(.plus);     i = input.index(after: i)
        case "-": tokens.append(.minus);    i = input.index(after: i)
        case "*": tokens.append(.multiply); i = input.index(after: i)
        case "/": tokens.append(.divide);   i = input.index(after: i)
        case "%": tokens.append(.modulo);   i = input.index(after: i)
        default:  throw CalculatorExpressionError.evaluationFailed
        }
    }
    return tokens
}

// MARK: - Parser

private struct Parser {
    let tokens: [Token]
    var pos: Int = 0

    init(input: String) throws {
        self.tokens = try tokenize(input)
    }

    var current: Token? { pos < tokens.count ? tokens[pos] : nil }
    var isAtEnd: Bool { pos >= tokens.count }

    mutating func advance() { pos += 1 }

    // expr = term (('+' | '-') term)*
    mutating func parseExpr() throws -> Double {
        var lhs = try parseTerm()
        while let t = current, t == .plus || t == .minus {
            advance()
            let rhs = try parseTerm()
            lhs = t == .plus ? lhs + rhs : lhs - rhs
        }
        return lhs
    }

    // term = factor (('*' | '/' | '%') factor)*
    mutating func parseTerm() throws -> Double {
        var lhs = try parseFactor()
        while let t = current, t == .multiply || t == .divide || t == .modulo {
            advance()
            let rhs = try parseFactor()
            switch t {
            case .multiply:
                lhs *= rhs
            case .divide:
                guard rhs != 0 else { throw CalculatorExpressionError.evaluationFailed }
                lhs /= rhs
            case .modulo:
                guard rhs != 0 else { throw CalculatorExpressionError.evaluationFailed }
                lhs = lhs.truncatingRemainder(dividingBy: rhs)
            default:
                break
            }
        }
        return lhs
    }

    // factor = ('+' | '-') factor | number
    mutating func parseFactor() throws -> Double {
        switch current {
        case .minus:
            advance()
            return try -parseFactor()
        case .plus:
            // unary plus — handles edge cases like "+3" or expressions starting after operator replacement
            advance()
            return try parseFactor()
        case .number(let value):
            advance()
            return value
        default:
            throw CalculatorExpressionError.evaluationFailed
        }
    }
}
