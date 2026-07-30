//
//  CityCapsule.swift
//  MagicTricks
//
//  Created by Ross on 29/07/2026.
//

import SwiftUI

struct CityCapsule: View {
    let city: String

    var body: some View {
        Text(city)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(Color.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background {
                Capsule()
                    .fill(Color.grayCard)
                    .overlay {
                        Capsule()
                            .stroke(Color.grayBorder, lineWidth: 1)
                    }
            }
    }
}

#Preview {
    CityCapsule(city: "Amsterdam")
        .padding()
}
