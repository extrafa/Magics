//
//  TrickCardActions.swift
//  Magic Tricks
//
//  Created by Ross on 10/04/2026.
//

import SwiftUI

struct TrickCardActions: View {
    let onStartTap: () -> Void
    let onHowToTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onHowToTap) {
                Text(String(localized: "collection.howTo"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .buttonStyle(SecondaryTrickButtonStyle())

            Button(action: onStartTap) {
                Text(String(localized: "collection.start"))
                    .font(.headline)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PrimaryTrickButtonStyle(color: .button))
        }
    }
}
