//
//  CardSurface.swift
//  Magic Tricks
//

import SwiftUI

extension View {
    func cardSurface(cornerRadius: CGFloat = 22) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.cardBorder, lineWidth: 1)
                }
        }
    }

    func cardSurface<S: InsettableShape>(_ shape: S) -> some View {
        background {
            shape
                .fill(Color.cardBackground)
                .overlay {
                    shape.stroke(Color.cardBorder, lineWidth: 1)
                }
        }
    }
}
