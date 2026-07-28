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
    let action: (String) -> Void
    
    var body: some View {
        Button {
            action(label)
        } label: {
            ZStack {
                if label == "delete.left" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 32))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(x: -2)
                } else {
                    Text(label)
                        .font(.system(size: 32))
                        .fontWeight(.medium)
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
        CalculatorPredictionButtonView(label: "delete.left", buttonSize: buttonSize) { _ in }
    }
}
