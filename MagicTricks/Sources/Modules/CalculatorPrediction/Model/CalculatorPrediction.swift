//
//  CalculatorPrediction.swift
//  Magic Tricks
//
//  Created by Ross on 31/01/2026.
//

import SwiftUI

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
    
    var buttonColor: Color {
        switch self {
        case .divide, .multiple, .subtract, .add, .equal:
            return Color(#colorLiteral(red: 1, green: 0.5713006854, blue: 0.005122783594, alpha: 1))
        case .delete, .clear, .percent: return Color(#colorLiteral(red: 0.3568627536, green: 0.3568627536, blue: 0.3568627536, alpha: 1))
        default:
            return Color(#colorLiteral(red: 0.1882353127, green: 0.1882353127, blue: 0.1882353127, alpha: 1))
        }
    }
}
