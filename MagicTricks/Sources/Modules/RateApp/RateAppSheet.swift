//
//  RateAppSheet.swift
//  Magic Tricks
//
//  Created by Ross on 13/08/2026.
//

import SwiftUI
import StoreKit

struct RateAppSheet: View {

    @EnvironmentObject private var flow: AppFlowCoordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @State private var phase: Phase = .question

    private enum Phase {
        case question
        case disliked
    }

    var body: some View {
        VStack(spacing: 0) {
            switch phase {
            case .question:
                questionView
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            case .disliked:
                dislikedView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(duration: 0.4, bounce: 0.1), value: phase)
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .fontDesign(.rounded)
        .presentationDetents([.height(300)])
        .presentationBackground(Color.background)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    // MARK: - Question

    private var questionView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Do you enjoy the app?")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primaryText)
                Text("Your feedback helps us improve.")
                    .font(.subheadline)
                    .foregroundStyle(.secondaryText)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                reactionButton(emoji: "👍", label: "I love it", action: handleLike)
                reactionButton(emoji: "👎", label: "Not really", action: handleDislike)
            }
        }
    }

    private func reactionButton(emoji: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 36))
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.grayCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.grayBorder, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Disliked

    private var dislikedView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("✉️")
                    .font(.system(size: 44))
                Text("We'd love to hear from you.")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primaryText)
                Text("Tell us what could be better.")
                    .font(.subheadline)
                    .foregroundStyle(.secondaryText)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button(action: handleWriteToUs) {
                    Text("Write to us")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryTrickButtonStyle(color: .button))

                Button(action: handleMaybeLater) {
                    Text("Maybe later")
                        .font(.subheadline)
                        .foregroundStyle(.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func handleLike() {
        AppPreferences.shared.hasRespondedToRating = true
        dismiss()
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            await MainActor.run { requestReview() }
        }
    }

    private func handleDislike() {
        withAnimation { phase = .disliked }
    }

    private func handleWriteToUs() {
        AppPreferences.shared.hasRespondedToRating = true
        let address = AppConfig.supportEmail
        let subject = "Magic Tricks Feedback"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(address)?subject=\(encodedSubject)") {
            UIApplication.shared.open(url)
        }
        dismiss()
    }

    private func handleMaybeLater() {
        dismiss()
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            RateAppSheet()
                .environmentObject(AppFlowCoordinator())
        }
}
