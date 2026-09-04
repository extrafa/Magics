//
//  SettingsComponents.swift
//  Magic Tricks
//
//  Created by Ross on 24/04/2026.
//

import SwiftUI

struct SettingsSection<Content: View>: View {

    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary.opacity(0.85))

            VStack(alignment: .leading, spacing: 0) {
                content
            }
        }
    }
}

struct SettingsActionRow: View {

    let icon: String
    let title: String
    var tint: Color? = nil
    var isBold = false
    var showsChevron = false

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint ?? .secondary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 17, weight: isBold ? .bold : .semibold, design: .rounded))
                .foregroundStyle(tint ?? .primaryText)

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.primaryText.opacity(0.34))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .contentShape(Rectangle())
    }
}

struct SettingsDivider: View {

    var body: some View {
        Divider()
            .overlay(Color.primary.opacity(0.1))
            .padding(.leading, 37)
    }
}

struct SettingsResetButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsActionRow(
                icon: "arrow.counterclockwise",
                title: String(localized: "settings.resetToDefault"),
                tint: .red,
                isBold: true
            )
            .padding(.horizontal, 18)
            .settingsCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Snap Slider

struct SettingsSnapSlider: View {

    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String

    @State private var generator = UISelectionFeedbackGenerator()
    @State private var lastHapticStep: Int?

    var body: some View {
        VStack(spacing: 12) {
            Text(String(format: format, value))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(TrickPalette.Collection.timeControl)
                .animation(.easeInOut(duration: 0.12), value: value)

            Slider(value: $value, in: range, step: step)
                .tint(TrickPalette.Collection.timeControl)
                .onChange(of: value) { newValue in
                    let currentStep = Int(round((newValue - range.lowerBound) / step))
                    guard currentStep != lastHapticStep else { return }
                    lastHapticStep = currentStep
                    generator.selectionChanged()
                }

            HStack {
                Text(String(format: format, range.lowerBound))
                Spacer()
                Text(String(format: format, range.upperBound))
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary.opacity(0.7))
        }
        .onAppear {
            lastHapticStep = Int(round((value - range.lowerBound) / step))
            generator.prepare()
        }
    }
}

// MARK: - Stepper

struct SettingsStepper: View {

    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String

    var body: some View {
        HStack(spacing: 0) {
            stepButton(icon: "minus", action: decrement)
                .disabled(value <= range.lowerBound)

            Spacer()

            Text(String(format: format, value))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primaryText)

            Spacer()

            stepButton(icon: "plus", action: increment)
                .disabled(value >= range.upperBound)
        }
        .foregroundStyle(TrickPalette.Collection.timeControl)
    }

    private func stepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func increment() {
        value = min(range.upperBound, ((value + step) * 100).rounded() / 100)
    }

    private func decrement() {
        value = max(range.lowerBound, ((value - step) * 100).rounded() / 100)
    }
}

// MARK: - Card background modifier

extension View {
    func settingsCard() -> some View {
        self.background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.grayCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.grayBorder, lineWidth: 1)
                }
        }
    }
}
