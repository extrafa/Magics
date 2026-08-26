//
//  PhantomDrawView.swift
//  Magic Tricks
//

import SwiftUI

struct PhantomDrawView: View {

    @StateObject private var viewModel = PhantomDrawViewModel()
    @Environment(\.dismiss) private var dismiss
    @AppStorage("phantomDrawLastCode") private var codeInput = ""

    private var state: PhantomDrawConnectionState { viewModel.session.connectionState }

    private var isSenderCanvas: Bool {
        guard viewModel.role == .sender, case .connected = state else { return false }
        return true
    }

    var body: some View {
        NavigationStackCompat {
            ZStack {
                Color.background.ignoresSafeArea()
                contentView
            }
            .navigationTitle("Phantom Draw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !isSenderCanvas {
                        Button { stop() } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
        }
        .onDisappear { viewModel.stop() }
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
                searchingView
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
                statusView(
                    icon: "exclamationmark.triangle",
                    title: "Could Not Connect",
                    subtitle: "Make sure both phones are nearby and have the app open.",
                    buttonTitle: "Try Again",
                    action: retry
                )
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: state)
    }

    @ViewBuilder
    private var connectedView: some View {
        if viewModel.role == .receiver {
            PhantomDrawReceiverView(viewModel: viewModel)
        } else {
            PhantomDrawSenderView(viewModel: viewModel)
        }
    }

    // MARK: - Role Selection

    private var roleSelectionView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(TrickPalette.Collection.phantomDraw)

                VStack(spacing: 3) {
                    Text("Open this trick on both phones.")
                    Text("Then choose a role on each.")
                }
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 36)

            VStack(spacing: 14) {
                roleButton(
                    title: "This phone is mine",
                    subtitle: "I will watch the drawing here",
                    icon: "eye",
                    role: .receiver
                )
                roleButton(
                    title: "Give to spectator",
                    subtitle: "They draw on this phone",
                    icon: "hand.draw",
                    role: .sender
                )
            }
            .padding(.horizontal, 24)

            Spacer()

        }
    }

    private func roleButton(title: String, subtitle: String, icon: String, role: PhantomDrawRole) -> some View {
        Button {
            viewModel.selectRole(role)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(TrickPalette.Collection.phantomDraw.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(TrickPalette.Collection.phantomDraw)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primaryText)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.grayCard)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.grayBorder, lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Entering Code

    private var enteringCodeView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "number")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(TrickPalette.Collection.phantomDraw)
                Text("Enter the Code")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primaryText)
                Text("Type the code shown on the spectator's phone.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer().frame(height: 28)
            TextField("00", text: $codeInput)
                .keyboardType(.numberPad)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.primaryText)
                .multilineTextAlignment(.center)
                .frame(width: 120, height: 60)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.grayCard)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.grayBorder, lineWidth: 1)
                        }
                }
                .onChange(of: codeInput) { newValue in
                    codeInput = String(newValue.filter(\.isNumber).prefix(2))
                }
            Spacer().frame(height: 28)
            Button {
                viewModel.submitReceiverCode(codeInput)
            } label: {
                Text("Connect")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
            }
            .buttonStyle(PrimaryTrickButtonStyle(color: TrickPalette.Collection.phantomDraw))
            .disabled(codeInput.count != 2)
            .padding(.horizontal, 32)
            Spacer()
            Button("Cancel", action: stop)
                .font(.system(size: 16, weight: .medium, design: .rounded))
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
            Text(viewModel.role == .sender ? "Waiting..." : "Connecting...")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.primaryText)
            Spacer().frame(height: 8)
            Text(viewModel.role == .sender
                 ? "Waiting for the magician to connect."
                 : "Keep both phones close together.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
            if viewModel.role == .sender, let code = viewModel.session.pairingCode {
                Spacer().frame(height: 20)
                Text(code)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(TrickPalette.Collection.phantomDraw)
                Text("Enter this code on the other device")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Cancel", action: stop)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Status

    private func statusView(icon: String, title: String, subtitle: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
            Spacer().frame(height: 20)
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.primaryText)
            Spacer().frame(height: 8)
            Text(subtitle)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            Button(buttonTitle, action: action)
                .buttonStyle(PrimaryTrickButtonStyle(color: TrickPalette.Collection.phantomDraw))
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func retry() {
        guard let role = viewModel.role else { return }
        viewModel.selectRole(role)
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

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(color, lineWidth: 1.5)
                    .frame(width: 120, height: 120)
                    .scaleEffect(animating ? 1.0 : 0.25)
                    .opacity(animating ? 0 : 0.35 - Double(i) * 0.08)
                    .animation(
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
        .onAppear { animating = true }
    }
}
