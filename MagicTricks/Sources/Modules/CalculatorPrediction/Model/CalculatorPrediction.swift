//
//  CalculatorPrediction.swift
//  Magic Tricks
//
//  Created by Ross on 31/01/2026.
//

import Foundation

struct CalculatorPrediction {
    static let buttons: [CalculatorPredictionButton] = [
        .delete, .clear, .percent, .divide,
        .seven, .eight, .nine, .multiple,
        .four, .five, .six, .subtract,
        .one, .two, .three, .add,
        .negative, .zero, .decimal, .equal
    ]
}

enum CalculatorPredictionButton: String {
    case delete = "delete.left"
    case clear = "AC"
    case percent = "%"
    case divide = "÷"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case multiple = "×"
    case four = "4"
    case five = "5"
    case six = "6"
    case subtract = "−"
    case one = "1"
    case two = "2"
    case three = "3"
    case add = "+"
    case negative = "+/-"
    case zero = "0"
    case decimal = ","
    case equal = "="

    var displayLabel: String {
        switch self {
        case .decimal: Locale.current.decimalSeparator ?? rawValue
        default: rawValue
        }
    }
}
