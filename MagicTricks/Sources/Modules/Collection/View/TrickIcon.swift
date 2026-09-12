//
//  TrickIcon.swift
//  Magic Tricks
//
//  Created by Ross on 01/03/2026.
//

import SwiftUI

struct TrickIcon: View {

    @Environment(\.colorScheme) private var colorScheme
    let systemName: String
    let color: Color
    let size: CGSize

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(colorScheme == .light ? 0.16 : 0.15))
                .overlay {
                    Circle()
                        .stroke(color.opacity(colorScheme == .light ? 0.42 : 0.48), lineWidth: 1.6)
                }
                .frame(width: size.width, height: size.height)
                .shadow(color: color.opacity(colorScheme == .light ? 0.16 : 0.32), radius: 14, x: 0, y: 5)

            Image(systemName: systemName)
                .font(.system(size: size.width / 2, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

