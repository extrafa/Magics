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
                .font(.system(.caption, design: .rounded, weight: .bold))
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
                .font(.system(.body, design: .rounded, weight: isBold ? .bold : .semibold))
                .foregroundStyle(tint ?? .textPrimary)
                .multilineTextAlignment(.leading)

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.textPrimary.opacity(0.34))
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
    }
}

struct SettingsToggleRow<Accessories: View>: View {

    let title: String
    let subtitle: String
    var tint: Color = TrickPalette.Collection.timeControl
    @Binding var isOn: Bool
    // A line under the subtitle that says what is happening now, for example while a test waits.
    var status: String?
    // Small round buttons (info, test) that sit next to the title, outside the switch.
    @ViewBuilder let accessories: Accessories

    var body: some View {
        if Accessories.self == EmptyView.self {
            Toggle(isOn: $isOn) { texts }
                .tint(tint)
                .padding(18)
        } else {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        titleText
                        accessories
                    }
                    subtitleText
                    if let status {
                        Text(status)
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .foregroundStyle(tint)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { isOn.toggle() }

                Toggle(title, isOn: $isOn)
                    .labelsHidden()
                    .tint(tint)
            }
            .padding(18)
            .animation(.easeInOut(duration: 0.2), value: status)
        }
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleText
            subtitleText
        }
    }

    private var titleText: some View {
        Text(title)
            .font(.system(.body, design: .rounded, weight: .bold))
            .foregroundStyle(.textPrimary)
    }

    private var subtitleText: some View {
        Text(subtitle)
            .font(.system(.footnote, design: .rounded, weight: .medium))
            .foregroundStyle(Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

extension SettingsToggleRow where Accessories == EmptyView {
    init(title: String, subtitle: String, tint: Color = TrickPalette.Collection.timeControl, isOn: Binding<Bool>) {
        self.init(title: title, subtitle: subtitle, tint: tint, isOn: isOn, status: nil, accessories: { EmptyView() })
    }
}

// MARK: - Round buttons

// A small round button next to a setting: the "i" that explains it and the dot that lets you try it.
struct SettingsRoundButton: View {

    enum Style {
        case info
        case test
    }

    let style: Style
    // The test is running: the dot keeps moving.
    var isActive = false
    // The test has an answer: shows a check instead of the dot.
    var isDone = false
    // How long the running test waits, so a ring can count the time down; nil for a test without a deadline.
    var countdown: TimeInterval?
    let label: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ringProgress: CGFloat = 1

    private var symbol: String {
        switch style {
        case .info: "info"
        case .test: isDone ? "checkmark" : "dot.radiowaves.left.and.right"
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.textPrimary.opacity(0.75))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.primary.opacity(0.07)))
                .overlay(Circle().stroke(Color.primary.opacity(0.18), lineWidth: 1))
                .overlay {
                    if isActive, countdown != nil {
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(TrickPalette.Collection.timeControl, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                }
                .speakingPulse(isActive: isActive && !reduceMotion)
                // 44 pt is the minimum touch target; the circle itself stays small.
                .padding(8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(-8)
        .accessibilityLabel(label)
        .onChange(of: isActive) { active in
            guard let countdown else { return }
            ringProgress = 1
            if active {
                withAnimation(.linear(duration: countdown)) { ringProgress = 0 }
            }
        }
    }
}

private extension View {
    // The waves keep moving while a test runs (iOS 17 and later).
    @ViewBuilder
    func speakingPulse(isActive: Bool) -> some View {
        if #available(iOS 17.0, *) {
            symbolEffect(.variableColor.iterative.reversing, options: .repeating, isActive: isActive)
        } else {
            self
        }
    }
}

// MARK: - Info sheet

enum SettingsInfoTopic: String, Identifiable {
    case grouping
    case faceDown
    case faceDownMissed

    var id: String { rawValue }
}

// The sheet behind an "i" button: what the setting does, in a few plain lines.
struct SettingsInfoSheet: View {

    let topic: SettingsInfoTopic
    // Seconds the Face Down test waits, for the text that says it gave up.
    var faceDownTimeout: Int = 10

    @Environment(\.dismiss) private var dismiss

    private var icon: String {
        switch topic {
        case .grouping: "circle.grid.3x3.fill"
        case .faceDown: "iphone.and.arrow.forward"
        case .faceDownMissed: "questionmark.circle"
        }
    }

    private var title: String {
        switch topic {
        case .grouping: String(localized: "settings.info.grouping.title")
        case .faceDown: String(localized: "settings.info.faceDown.title")
        case .faceDownMissed: String(localized: "settings.info.faceDownMissed.title")
        }
    }

    private var message: String {
        switch topic {
        case .grouping: String(localized: "settings.info.grouping.message")
        case .faceDown: String(localized: "settings.info.faceDown.message")
        case .faceDownMissed:
            String.localizedStringWithFormat(String(localized: "settings.info.faceDownMissed.message"), faceDownTimeout)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(TrickPalette.Collection.timeControl)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(TrickPalette.Collection.timeControl.opacity(0.15)))
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(message)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if topic == .grouping {
                GroupingExample(groups: [3, 3, 1])
            }

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Text(String(localized: "common.gotIt"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PrimaryTrickButtonStyle(color: .buttonPrimary))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundScreen.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// Dots in groups: the number 7 as 3 + 3 + 1.
private struct GroupingExample: View {

    let groups: [Int]

    var body: some View {
        HStack(spacing: 18) {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, count in
                HStack(spacing: 5) {
                    ForEach(0..<count, id: \.self) { _ in
                        Circle()
                            .fill(TrickPalette.Collection.timeControl)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            Text(verbatim: "= \(groups.reduce(0, +))")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .cardSurface(cornerRadius: 16)
        .accessibilityHidden(true)
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
            .cardSurface(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stepper

struct SettingsStepper: View {

    @Binding var value: Double
    let label: String
    let range: ClosedRange<Double>
    let step: Double
    let format: String
    // The stored value is shown divided by this, so a default that is stored as 1.5 can read 1.0x.
    var displayScale: Double = 1
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 17

    var body: some View {
        HStack(spacing: 0) {
            stepButton(icon: "minus", action: decrement)
                .disabled(value <= range.lowerBound)

            Spacer()

            Text(displayText)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.textPrimary)

            Spacer()

            stepButton(icon: "plus", action: increment)
                .disabled(value >= range.upperBound)
        }
        .foregroundStyle(TrickPalette.Collection.timeControl)
        // One adjustable element for VoiceOver: swipe up or down changes the value.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(displayText)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: increment()
            case .decrement: decrement()
            @unknown default: break
            }
        }
    }

    private var displayText: String {
        Self.displayText(for: value, format: format, displayScale: displayScale)
    }

    static func displayText(for value: Double, format: String, displayScale: Double) -> String {
        String(format: format, value / displayScale)
    }

    // 44 pt is the minimum touch target; the button grows only once the icon outgrows it.
    private var buttonSide: CGFloat { max(44, iconSize * 1.55) }

    private func stepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .bold))
                .frame(width: buttonSide, height: buttonSide)
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
