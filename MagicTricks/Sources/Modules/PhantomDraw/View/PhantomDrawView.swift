//
//  PhantomDrawView.swift
//  Magic Tricks
//

import Combine
import SwiftUI

private let introKey = L10nDomain("phantomDraw.intro")
private let receiverKey = L10nDomain("phantomDraw.role.receiver")
private let senderKey = L10nDomain("phantomDraw.role.sender")
private let enterCodeKey = L10nDomain("phantomDraw.enterCode")
private let statusKey = L10nDomain("phantomDraw.status")
private let statusFailedKey = KeyDomain("phantomDraw.status.failed")
private let statusDeniedKey = KeyDomain("phantomDraw.status.localNetworkDenied")
private let statusEndedKey = KeyDomain("phantomDraw.status.ended")

struct PhantomDrawView: View {

    // Holds the objects without subscribing to them: the canvases observe them themselves, so a drawn point
    // doesn't re-run this root body. Only the three low-frequency values below are mirrored into @State.
    @MainActor
    private final class Dependencies: ObservableObject {
        let session: PhantomDrawSessionManager
        let viewModel: PhantomDrawViewModel

        init(session: PhantomDrawSessionManager) {
            self.session = session
            viewModel = PhantomDrawViewModel(session: session)
        }
    }

    @StateObject private var dependencies: Dependencies
    @State private var state: PhantomDrawConnectionState = .idle
    @State private var role: PhantomDrawRole?
    @State private var pairingCode: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var flow: AppFlowCoordinator
    @EnvironmentObject private var store: StoreManager
    @State private var codeInput = ""
    @AppStorage("phantomDrawLastCode") private var lastCode = ""
    @FocusState private var isCodeFieldFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var scaledCodeFieldWidth: CGFloat = 120
    @ScaledMetric(relativeTo: .largeTitle) private var codeFieldHeight: CGFloat = 60
    @ScaledMetric(relativeTo: .largeTitle) private var pairingCodeSize: CGFloat = 44

    // Two digits stay readable well before the field would outgrow a narrow screen.
    private var codeFieldWidth: CGFloat { min(scaledCodeFieldWidth, 220) }

    init(session: PhantomDrawSessionManager? = nil) {
        _dependencies = StateObject(wrappedValue: Dependencies(session: session ?? PhantomDrawSessionManager()))
    }

    private var session: PhantomDrawSessionManager { dependencies.session }
    private var viewModel: PhantomDrawViewModel { dependencies.viewModel }

    private var isSenderCanvas: Bool {
        guard role == .sender, case .connected = state else { return false }
        return true
    }

    var body: some View {
        ZStack {
            Color.backgroundScreen.ignoresSafeArea()
            contentView
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !isSenderCanvas {
                    Button { stop() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(String(localized: "common.close"))
                }
            }
        }
        .onDisappear { viewModel.stop() }
        .onReceive(session.$connectionState.removeDuplicates()) { state = $0 }
        .onReceive(viewModel.$role.removeDuplicates()) { role = $0 }
        .onReceive(session.$pairingCode.removeDuplicates()) { pairingCode = $0 }
        .onChange(of: state) { newState in
            if case .connected = newState, role == .receiver, codeInput.count == 2 {
                lastCode = codeInput
            }
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ZStack {
            if case .idle = state {
                roleSelectionView
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .offset(y: 24))
                    ))
            }

            if case .enteringCode = state {
                enteringCodeView
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .offset(y: 24))
                    ))
            }

            if case .searching = state {
                scrollingScreen { searchingView }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: -16)),
                        removal: .opacity.combined(with: .offset(y: 16))
                    ))
            }

            if case .connected = state {
                connectedView
                    .transition(.opacity)
            }

            if case .failed = state {
                scrollingScreen {
                    statusView(
                        icon: "exclamationmark.triangle",
                        title: LocalizedStringKey(stringLiteral: statusFailedKey("title")),
                        subtitle: LocalizedStringKey(stringLiteral: statusFailedKey("subtitle")),
                        buttonTitle: LocalizedStringKey(stringLiteral: statusFailedKey("retry")),
                        action: retry
                    )
                }
                .transition(.opacity)
            }

            if case .ended = state {
                scrollingScreen {
                    statusView(
                        icon: "checkmark.circle",
                        title: LocalizedStringKey(stringLiteral: statusEndedKey("title")),
                        subtitle: LocalizedStringKey(stringLiteral: statusEndedKey("subtitle")),
                        buttonTitle: "common.close",
                        action: stop,
                        secondaryTitle: LocalizedStringKey(stringLiteral: statusFailedKey("retry")),
                        secondaryAction: retryAfterDenial
                    )
                }
                .transition(.opacity)
            }

            if case .localNetworkDenied = state {
                scrollingScreen {
                    statusView(
                        icon: "wifi.exclamationmark",
                        title: LocalizedStringKey(stringLiteral: statusDeniedKey("title")),
                        subtitle: LocalizedStringKey(stringLiteral: statusDeniedKey("subtitle")),
                        buttonTitle: "common.openSettings",
                        action: openSettings,
                        secondaryTitle: LocalizedStringKey(stringLiteral: statusFailedKey("retry")),
                        secondaryAction: retryAfterDenial
                    )
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: state)
    }

    @ViewBuilder
    private var connectedView: some View {
        if role == .receiver {
            PhantomDrawReceiverView(session: session)
        } else {
            PhantomDrawSenderView(viewModel: viewModel, onExit: stop)
        }
    }

    // Screens that are a centred column: scrollable so larger text is never cut off, still filling the screen when it fits.
    private func scrollingScreen<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let content = content()
        return GeometryReader { proxy in
            ScrollView {
                content
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
    }

    // MARK: - Role Selection

    private var roleSelectionView: some View {
        scrollingScreen { roleSelectionContent }
    }

    private var roleSelectionContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(TrickPalette.Collection.phantomDraw)

                VStack(spacing: 3) {
                    Text(String(localized: introKey("line1")))
                    Text(String(localized: introKey("line2")))
                }
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 36)

            VStack(spacing: 14) {
                roleButton(
                    title: String(localized: receiverKey("title")),
                    subtitle: String(localized: receiverKey("subtitle")),
                    icon: "eye",
                    role: .receiver
                )
                roleButton(
                    title: String(localized: senderKey("title")),
                    subtitle: String(localized: senderKey("subtitle")),
                    icon: "hand.draw",
                    role: .sender
                )
            }
            .padding(.horizontal, 24)

            Spacer()

        }
    }

    private func roleButton(title: String, subtitle: String, icon: String, role: PhantomDrawRole) -> some View {
        let isLocked = role.requiresPro && store.showsFreeTier
        return Button {
            Task {
                await store.waitForResolvedAccess()
                if role.requiresPro && !store.hasProAccess {
                    flow.presentPaywallOverlay(context: .trick(.phantomDraw))
                } else {
                    viewModel.selectRole(role)
                }
            }
        } label: {
            // The icon and chevron flank the text; at accessibility sizes they move to a row above it so words aren't split.
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            roleIcon(icon)
                            Spacer()
                            roleAccessories(isLocked: isLocked)
                        }
                        roleTexts(title: title, subtitle: subtitle)
                    }
                } else {
                    HStack(spacing: 16) {
                        roleIcon(icon)
                        roleTexts(title: title, subtitle: subtitle)
                        Spacer()
                        roleAccessories(isLocked: isLocked)
                    }
                }
            }
            .padding(18)
            .cardSurface(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    private func roleIcon(_ icon: String) -> some View {
        ZStack {
            Circle()
                .fill(TrickPalette.Collection.phantomDraw.opacity(0.15))
                .frame(width: 48, height: 48)
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(TrickPalette.Collection.phantomDraw)
        }
    }

    private func roleTexts(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(.textPrimary)
            Text(subtitle)
                .font(.system(.footnote, design: .rounded, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    private func roleAccessories(isLocked: Bool) -> some View {
        HStack(spacing: 16) {
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.primary.opacity(0.45))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.07)))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(Color.primary.opacity(0.22), lineWidth: 1.2)
                    }
                    .accessibilityLabel(String(localized: "trick.lockedBadge"))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary.opacity(0.5))
        }
    }

    // MARK: - Entering Code

    private var enteringCodeView: some View {
        scrollingScreen { enteringCodeContent }
    }

    private var enteringCodeContent: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "number")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(TrickPalette.Collection.phantomDraw)
                    .accessibilityHidden(true)
                Text(String(localized: enterCodeKey("title")))
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                Text(String(localized: enterCodeKey("description")))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer().frame(height: 28)
            ZStack {
                if !isCodeFieldFocused && codeInput.isEmpty {
                    Text(String(localized: "phantomDraw.codePlaceholder"))
                        .foregroundStyle(.secondary)
                }
                TextField("", text: $codeInput)
                    .keyboardType(.numberPad)
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)
                    .focused($isCodeFieldFocused)
            }
            .font(.system(.largeTitle, design: .rounded, weight: .black))
            .frame(width: codeFieldWidth, height: codeFieldHeight)
            .cardSurface(cornerRadius: 16)
            .onChange(of: codeInput) { newValue in
                codeInput = String(newValue.filter(\.isNumber).prefix(2))
            }
            if !lastCode.isEmpty {
                Spacer().frame(height: 12)
                Text(String(format: String(localized: "phantomDraw.lastCodeHint"), lastCode))
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer().frame(height: 28)
            primaryButton("phantomDraw.connect", disabled: codeInput.count != 2) {
                viewModel.submitReceiverCode(codeInput)
            }
            Spacer()
            Button(String(localized: "common.cancel"), action: stop)
                .font(.system(.callout, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Searching

    private var searchingView: some View {
        VStack(spacing: 0) {
            Spacer()
            PulsingSignalView(color: TrickPalette.Collection.phantomDraw)
                .frame(width: 120, height: 120)
            Spacer().frame(height: 28)
            Text(String(localized: statusKey(role == .sender ? "waiting" : "connecting")))
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 8)
            Text(String(localized: statusKey(role == .sender
                 ? "waitingDescription"
                 : "connectingDescription")))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if role == .sender, let code = pairingCode {
                Spacer().frame(height: 20)
                Text(code)
                    .font(.system(size: pairingCodeSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(TrickPalette.Collection.phantomDraw)
                Text(String(localized: "phantomDraw.enterCodeOnOtherDevice"))
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button(String(localized: "common.cancel"), action: stop)
                .font(.system(.callout, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .keepsScreenAwake()
    }

    // MARK: - Status

    private func statusView(
        icon: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        buttonTitle: LocalizedStringKey,
        action: @escaping Completion,
        secondaryTitle: LocalizedStringKey? = nil,
        secondaryAction: Completion? = nil
    ) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Spacer().frame(height: 20)
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 8)
            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            primaryButton(buttonTitle, action: action)
                .padding(.bottom, secondaryTitle == nil ? 32 : 16)
            if let secondaryTitle, let secondaryAction {
                Button(secondaryTitle, action: secondaryAction)
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func primaryButton(_ title: LocalizedStringKey, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(PrimaryTrickButtonStyle(color: TrickPalette.Collection.phantomDraw))
        .disabled(disabled)
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func retry() {
        guard let currentRole = viewModel.role else { return }
        viewModel.selectRole(currentRole)
    }

    // Looks again with the code already typed, instead of making the performer enter it a second time.
    private func retryAfterDenial() {
        if role == .receiver, codeInput.count == 2 {
            viewModel.submitReceiverCode(codeInput)
        } else {
            retry()
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func stop() {
        viewModel.stop()
        codeInput = ""
        dismiss()
    }
}

// MARK: - PulsingSignalView

private struct PulsingSignalView: View {

    let color: Color
    @State private var animating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(color, lineWidth: 1.5)
                    .frame(width: 120, height: 120)
                    .scaleEffect(reduceMotion || animating ? 1.0 : 0.25)
                    // Reduce Motion keeps one still ring instead of the rings spreading out forever.
                    .opacity(reduceMotion ? (i == 0 ? 0.25 : 0) : (animating ? 0 : 0.35 - Double(i) * 0.08))
                    .animation(
                        reduceMotion ? nil :
                        .easeOut(duration: 1.6)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.45),
                        value: animating
                    )
            }
            Circle()
                .fill(color.opacity(0.15))
                .overlay(Circle().stroke(color, lineWidth: 2))
                .frame(width: 48, height: 48)
            Image(systemName: "wifi")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(color)
        }
        .onAppear { animating = !reduceMotion }
    }
}
