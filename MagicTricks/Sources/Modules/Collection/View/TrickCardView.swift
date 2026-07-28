//
//  TrickCardView.swift
//  Magic Tricks
//
//  Created by Ross on 10/04/2026.
//

import SwiftUI

struct TrickCardView: View {

    let trick: Trick
    let onStartTap: () -> Void
    let onHowToTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            buttons
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 208, alignment: .topLeading)
        .background { cardBackground }
        .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 8)
        .overlay(alignment: .topTrailing) {
            TrickDifficultyBadge(difficulty: trick.difficulty)
                .padding(.top, 16)
                .padding(.trailing, 16)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.grayCard)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.grayBorder, lineWidth: 1)
            }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            TrickIcon(
                systemName: trick.image,
                color: trick.id.collectionColor,
                size: CGSize(width: 54, height: 54)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(trick.cardTitle ?? trick.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 88)

                Text(trick.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)
        }
    }

    private var buttons: some View {
        TrickCardActions(onStartTap: onStartTap, onHowToTap: onHowToTap)
    }
}

#Preview {
    TrickCardView(
        trick: TrickCollection.tricks[0],
        onStartTap: {},
        onHowToTap: {}
    )
    .padding()
}
