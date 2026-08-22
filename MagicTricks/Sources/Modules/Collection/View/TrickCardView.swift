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
        ZStack(alignment: .topTrailing) {
            cardBody
                .grayscale(isLocked ? 1.0 : 0)
                .opacity(isLocked ? 0.52 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isLocked)
                .overlay {
                    if isLocked {
                        Color.clear
                            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .onTapGesture { onStartTap() }
                    }
                }

            badge
                .padding(.top, 16)
                .padding(.trailing, 16)
        }
    }

    // MARK: Card

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer(minLength: 16)
            TrickCardActions(onStartTap: onStartTap, onHowToTap: onHowToTap)
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 208, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.grayCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.grayBorder, lineWidth: 1)
                }
        }
        .shadow(color: Color.black.opacity(isLocked ? 0.03 : 0.06), radius: 18, x: 0, y: 8)
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
                    .font(.title3.weight(.bold))
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

    // MARK: Badge

    @ViewBuilder
    private var badge: some View {
        if isLocked {
            proBadge
        } else {
            TrickDifficultyBadge(difficulty: trick.difficulty)
        }
    }

    private var proBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9, weight: .bold))
            Text("PRO")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.4)
        }
        .foregroundStyle(Color.primary.opacity(0.45))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.07)))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.primary.opacity(0.22), lineWidth: 1.2)
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
