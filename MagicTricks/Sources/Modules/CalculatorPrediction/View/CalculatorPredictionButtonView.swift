//
//  CalculatorPredictionButtonView.swift
//  Magic Tricks
//
//  Created by Ross on 31/01/2026.
//

import SwiftUI

struct CalculatorPredictionButtonView: View {

    let label: String
    let buttonSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if label == "delete.left" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 32))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(x: -2)
                } else {
                    Text(label)
                        .font(.system(size: 32, weight: .medium))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(CalculatorPredictionButton(rawValue: label)?.buttonColor ?? .gray)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
    }
    
}

#Preview {
    GeometryReader { geometry in
        let buttonSize = (geometry.size.width - 5 * 12) / 4
        CalculatorPredictionButtonView(label: "delete.left", buttonSize: buttonSize) { }
    }
}

private extension CalculatorPredictionButton {
    var buttonColor: Color {
        switch self {
        case .divide, .multiple, .subtract, .add, .equal:
            return Color(#colorLiteral(red: 1, green: 0.5713006854, blue: 0.005122783594, alpha: 1))
        case .delete, .clear, .percent:
            return Color(#colorLiteral(red: 0.3568627536, green: 0.3568627536, blue: 0.3568627536, alpha: 1))
        default:
            return Color(#colorLiteral(red: 0.1882353127, green: 0.1882353127, blue: 0.1882353127, alpha: 1))
        }
    }
}
