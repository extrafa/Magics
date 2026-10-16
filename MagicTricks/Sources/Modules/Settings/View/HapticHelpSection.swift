//
//  HapticHelpSection.swift
//  Magic Tricks
//
//  Created by Ross on 13/08/2026.
//

import SwiftUI

private let key = L10nDomain("settings.help")

struct HapticHelpSection: View {

    private let items: [(question: String, answer: String)] = [
        (
            String(localized: key("exitHint.question")),
            String(localized: key("exitHint.answer"))
        ),
        (
            String(localized: key("noVibration.question")),
            String(localized: key("noVibration.answer"))
        ),
    ]

    var body: some View {
        SettingsSection(title: String(localized: key("title"))) {
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
            .cardSurface(cornerRadius: 20)
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
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.textPrimary.opacity(0.35))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(answer)
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.bottom, isExpanded ? 16 : 0)
                .frame(maxHeight: isExpanded ? .infinity : 0, alignment: .top)
                .opacity(isExpanded ? 1 : 0)
                .clipped()
        }
    }
}

// MARK: - Vibration help sheet

struct VibrationHelpLink: View {

    @State private var isSheetPresented = false

    var body: some View {
        Button {
            isSheetPresented = true
        } label: {
            Text(String(localized: key("noVibration.link")))
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .underline()
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isSheetPresented) {
            VibrationHelpSheet()
        }
    }
}

private struct VibrationHelpSheet: View {

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(String(localized: key("noVibration.question")))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)

                Text(String(localized: key("noVibration.answer")))
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: openSettings) {
                    Text(String(localized: "common.openSettings"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryTrickButtonStyle(color: .buttonPrimary))
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .presentationDragIndicator(.visible)
        .modifier(VibrationHelpPresentationModifier())
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct VibrationHelpPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationDetents([.medium, .large])
                .presentationBackground(Color.backgroundScreen)
                .presentationCornerRadius(28)
        } else {
            content
                .presentationDetents([.medium, .large])
        }
    }
}
