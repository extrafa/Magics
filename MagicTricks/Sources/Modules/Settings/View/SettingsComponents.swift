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
    // The small info button that sits next to the title, outside the switch.
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { isOn.toggle() }

                Toggle(title, isOn: $isOn)
                    .labelsHidden()
                    .tint(tint)
            }
            .padding(18)
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
        self.init(title: title, subtitle: subtitle, tint: tint, isOn: isOn, accessories: { EmptyView() })
    }
}

// MARK: - Info button

// A small "i" next to a setting's title, the size of the title text; it opens the sheet that explains the setting.
struct SettingsInfoButton: View {

    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                // 44 pt is the minimum touch target; the icon itself stays the size of the title.
                .padding(11)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(-11)
        .accessibilityLabel(label)
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
    @State private var contentHeight: CGFloat = 0

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
        .padding(.horizontal, 24)
        .padding(.top, 68)
        .padding(.bottom, 24)
        // The sheet is as tall as its text, so no empty room opens under the button (a preference key did not report here).
        .background(GeometryReader { proxy in
            Color.clear
                .onAppear { contentHeight = proxy.size.height }
                .onChange(of: proxy.size.height) { contentHeight = $0 }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.backgroundScreen.ignoresSafeArea())
        .sheetCloseOverlay()
        .modifier(InfoSheetPresentation(height: contentHeight))
        .presentationDragIndicator(.visible)
    }
}

// The sheet itself takes the screen colour, so no strip of the system sheet shows around the content.
private struct InfoSheetPresentation: ViewModifier {
    // The measured height of the content; 0 until it is known.
    let height: CGFloat

    private var detents: Set<PresentationDetent> {
        height > 0 ? [.height(height), .large] : [.medium, .large]
    }

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationDetents(detents)
                .presentationBackground(Color.backgroundScreen)
                .presentationCornerRadius(28)
        } else {
            content
                .presentationDetents(detents)
        }
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
        value = Self.stepped(value, by: step, in: range)
    }

    private func decrement() {
        value = Self.stepped(value, by: -step, in: range)
    }

    // Rounded to three decimals so repeated steps of 0.375 land on 1.125, 1.5, 1.875 and do not drift.
    static func stepped(_ value: Double, by delta: Double, in range: ClosedRange<Double>) -> Double {
        min(range.upperBound, max(range.lowerBound, ((value + delta) * 1000).rounded() / 1000))
    }
}
