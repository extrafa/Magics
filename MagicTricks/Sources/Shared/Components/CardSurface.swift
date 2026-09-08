//
//  CardSurface.swift
//  Magic Tricks
//

import SwiftUI

extension View {
    func cardSurface(cornerRadius: CGFloat = 22) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.grayCard)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.grayBorder, lineWidth: 1)
                }
        }
    }

    func cardSurface<S: InsettableShape>(_ shape: S) -> some View {
        background {
            shape
                .fill(Color.grayCard)
                .overlay {
                    shape.stroke(Color.grayBorder, lineWidth: 1)
                }
        }
    }
}
