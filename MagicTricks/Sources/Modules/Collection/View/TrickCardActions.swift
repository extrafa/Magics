//
//  TrickCardActions.swift
//  Magic Tricks
//
//  Created by Ross on 10/04/2026.
//

import SwiftUI

struct TrickCardActions: View {
    let trickName: String
    var isHowToLocked = false
    let onStartTap: () -> Void
    let onHowToTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onHowToTap) {
                HStack(spacing: 6) {
                    if isHowToLocked {
                        Image(systemName: "lock.fill")
                            .font(.subheadline)
                            .accessibilityHidden(true)
                    }
                    Text(String(localized: "collection.howTo"))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .buttonStyle(SecondaryTrickButtonStyle())
            // A free-tier phone (the spectator's) can't read this trick's instruction: the button stays, locked.
            .disabled(isHowToLocked)
            .opacity(isHowToLocked ? 0.45 : 1)
            .accessibilityLabel(String(format: String(localized: "collection.howTo.accessibilityLabel"), trickName))

            Button(action: onStartTap) {
                Text(String(localized: "collection.start"))
                    .font(.headline)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PrimaryTrickButtonStyle(color: .buttonPrimary))
            .accessibilityLabel(String(format: String(localized: "collection.start.accessibilityLabel"), trickName))
        }
    }
}
