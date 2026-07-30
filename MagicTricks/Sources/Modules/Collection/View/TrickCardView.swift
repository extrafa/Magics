//
//  TrickCardView.swift
//  Magic Tricks
//
//  Created by Ross on 10/04/2026.
//

import SwiftUI

struct TrickCardView: View {

    let trick: Trick
    let isLocked: Bool
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
            if isLocked {
                proBadge
                    .padding(.top, 16)
                    .padding(.trailing, 16)
            } else {
                TrickDifficultyBadge(difficulty: trick.difficulty)
                    .padding(.top, 16)
                    .padding(.trailing, 16)
            }
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

    private var proBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9, weight: .bold))
            Text("PRO")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.4)
        }
        .foregroundStyle(Color.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Capsule(style: .continuous).fill(Color.orange.opacity(0.14)))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.orange.opacity(0.42), lineWidth: 1.2)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TrickCardView(
            trick: TrickCollection.tricks[0],
            isLocked: false,
            onStartTap: {},
            onHowToTap: {}
        )
        TrickCardView(
            trick: TrickCollection.tricks[1],
            isLocked: true,
            onStartTap: {},
            onHowToTap: {}
        )
    }
    .padding()
}
