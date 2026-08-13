//
//  HapticHelpSection.swift
//  Magic Tricks
//
//  Created by Ross on 13/08/2026.
//

import SwiftUI

struct HapticHelpSection: View {

    private let items: [(question: String, answer: String)] = [
        (
            String(localized: "settings.help.exitHint.question"),
            String(localized: "settings.help.exitHint.answer")
        ),
    ]

    var body: some View {
        SettingsSection(title: String(localized: "settings.help.title")) {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    if index > 0 {
                        Divider()
                            .overlay(Color.primary.opacity(0.1))
                            .padding(.leading, 18)
                    }
                    HelpItem(question: item.question, answer: item.answer)
                }
            }
            .settingsCard()
        }
    }
}

private struct HelpItem: View {
    let question: String
    let answer: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Text(question)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.primaryText.opacity(0.35))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(answer)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.primaryText.opacity(0.58))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.bottom, isExpanded ? 16 : 0)
                .frame(maxHeight: isExpanded ? 300 : 0, alignment: .top)
                .opacity(isExpanded ? 1 : 0)
                .clipped()
        }
    }
}
