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
// The blue of the other tappable controls (the speed buttons) shows it can be pressed, and it dims while pressed.
struct SettingsInfoButton: View {

    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(TrickPalette.Collection.timeControl)
                // 44 pt is the minimum hit region; the icon itself stays the size of the title.
                .padding(11)
                .contentShape(Rectangle())
        }
        .buttonStyle(InfoButtonStyle())
        .padding(-11)
        .accessibilityLabel(label)
    }
}

private struct InfoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.4 : 1)
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
    // Plays the example on the grouping sheet; nil where nothing should be felt.
    var haptics: CountHapticPlaying?

    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 0
    // Which run of the example this is and how many of its pulses have fired; each dot jumps when its own pulse is reached.
    @State private var progress = GroupingDemoProgress()
    // Counts the taps on the replay button; a new value starts the example again.
    @State private var replayCount = 0
    // The pulses are playing: a tap on the replay button does nothing until they end.
    @State private var isPlaying = false

    // A short wait after the sheet opens, so the person is looking at the dots when they start to move.
    private static let demoStartDelay: TimeInterval = 0.8
    // The dot starts a little before the pulse: the screen draws a frame later than the phone buzzes.
    private static let dotLead: TimeInterval = 0.04
    private static let exampleGroups = [3, 3, 1]

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

    // What to do with it, kept apart from the description: the description says what happens in the trick, so it never reads as an order.
    private var hint: String {
        switch topic {
        case .grouping: String(localized: "settings.info.grouping.hint")
        case .faceDown: String(localized: "settings.info.faceDown.hint")
        case .faceDownMissed: String(localized: "settings.info.faceDownMissed.hint")
        }
    }

    var body: some View {
        ScrollView {
            content
        }
        // Only the height of its text: it cannot be pulled up to full screen; larger text scrolls inside it.
        .scrollBouncesOnlyWhenNeeded()
        .background(Color.backgroundScreen.ignoresSafeArea())
        // No close button in the corner: the big Got It button closes the sheet.
        .modifier(InfoSheetPresentation(height: contentHeight))
        .presentationDragIndicator(.visible)
        // The first run waits a moment; a replay starts at once.
        .task(id: replayCount) { await playGroupingDemo(startDelay: replayCount == 0 ? Self.demoStartDelay : 0) }
        .onDisappear {
            guard topic == .grouping else { return }
            haptics?.cancelPendingHaptics()
        }
    }

    private var content: some View {
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

            VStack(alignment: .leading, spacing: 12) {
                Text(message)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(hint)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if topic == .grouping {
                GroupingExample(
                    groups: Self.exampleGroups,
                    progress: progress,
                    onReplay: haptics == nil ? nil : {
                        guard !isPlaying else { return }
                        replayCount += 1
                    }
                )
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
        .padding(.top, 32)
        .padding(.bottom, 16)
        // The sheet is as tall as its text, so no empty room opens under the button (a preference key did not report here).
        .background(GeometryReader { proxy in
            Color.clear
                .onAppear { contentHeight = proxy.size.height }
                .onChange(of: proxy.size.height) { contentHeight = $0 }
        })
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // The example of the text, felt and seen: the phone pulses 3, 3 and 1 while the dots jump with each pulse.
    private func playGroupingDemo(startDelay: TimeInterval) async {
        guard topic == .grouping, let haptics else { return }
        progress = GroupingDemoProgress(run: progress.run + 1, fired: 0)
        if startDelay > 0 { try? await Task.sleep(seconds: startDelay) }
        guard !Task.isCancelled else { return }

        let count = Self.exampleGroups.reduce(0, +)
        let pulseTimes = haptics.groupedPulseTimes(count)
        haptics.playGroupedCount(count, completion: nil)
        isPlaying = true
        defer { isPlaying = false }

        let start = Date()
        for time in pulseTimes {
            let wait = (time - Self.dotLead) - Date().timeIntervalSince(start)
            if wait > 0 { try? await Task.sleep(seconds: wait) }
            guard !Task.isCancelled else {
                progress.fired = 0
                return
            }
            // Counted from the clock, not one by one: a late wake-up lets the dots catch up instead of skipping one.
            let elapsed = Date().timeIntervalSince(start) + Self.dotLead
            progress.fired = GroupingDemoClock.firedPulses(pulseTimes: pulseTimes, elapsed: elapsed)
        }
    }
}

// Where the example is: which run it is, and how many of that run's pulses have fired.
struct GroupingDemoProgress: Equatable {
    var run = 0
    var fired = 0
}

// What one dot remembers, so it jumps once per run, even when the run restarts before the screen has seen it at zero.
struct PulseDotMemory {
    private var run = 0
    private var hasJumped = false

    mutating func shouldJump(index: Int, progress: GroupingDemoProgress) -> Bool {
        if progress.run != run {
            run = progress.run
            hasJumped = false
        }
        guard progress.fired > index, !hasJumped else { return false }
        hasJumped = true
        return true
    }
}

// How many pulses of the example have fired after this long.
enum GroupingDemoClock {
    static func firedPulses(pulseTimes: [TimeInterval], elapsed: TimeInterval) -> Int {
        pulseTimes.filter { $0 <= elapsed }.count
    }
}

// The sheet itself takes the screen colour, so no strip of the system sheet shows around the content.
private struct InfoSheetPresentation: ViewModifier {
    // The measured height of the content; 0 until it is known.
    let height: CGFloat

    private var detents: Set<PresentationDetent> {
        height > 0 ? [.height(height)] : [.medium]
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

// Dots in groups: the number 7 as 3 + 3 + 1. A dot jumps when its pulse is felt.
private struct GroupingExample: View {

    let groups: [Int]
    var progress = GroupingDemoProgress()
    // Plays the example again; nil hides the button.
    var onReplay: Completion?

    var body: some View {
        HStack(spacing: 18) {
            ForEach(Array(groups.enumerated()), id: \.offset) { groupIndex, count in
                HStack(spacing: 5) {
                    ForEach(0..<count, id: \.self) { dot in
                        PulseDot(index: groups.prefix(groupIndex).reduce(0, +) + dot, progress: progress)
                    }
                }
            }
            Text(verbatim: "= \(groups.reduce(0, +))")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
        .cardSurface(cornerRadius: 16)
        .overlay(alignment: .trailing) {
            if let onReplay {
                Button(action: onReplay) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(TrickPalette.Collection.timeControl)
                        // 44 pt is the minimum hit region.
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(InfoButtonStyle())
                .accessibilityLabel(String(localized: "settings.info.grouping.replay"))
                .padding(.trailing, 4)
            }
        }
    }
}

// One dot of the example. It sees how many pulses have fired and, when its own is reached, jumps and comes back on its own
// clock, so a pulse that arrives late or together with the next one still shows.
private struct PulseDot: View {

    let index: Int
    let progress: GroupingDemoProgress

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isUp = false
    @State private var memory = PulseDotMemory()

    private static let holdDuration: TimeInterval = 0.09

    var body: some View {
        Circle()
            .fill(TrickPalette.Collection.timeControl)
            .frame(width: 12, height: 12)
            .scaleEffect(isUp ? 1.5 : 1)
            .offset(y: isUp ? -7 : 0)
            // With Reduce Motion the dots stay in place and light up one after another instead.
            .opacity(reduceMotion && progress.fired > 0 && index >= progress.fired ? 0.45 : 1)
            .onChange(of: progress) { newValue in
                if memory.shouldJump(index: index, progress: newValue) { jump() }
            }
    }

    private func jump() {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { isUp = true }
        Task {
            try? await Task.sleep(seconds: Self.holdDuration)
            withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) { isUp = false }
        }
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
