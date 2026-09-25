//
//  RateAppSheet.swift
//  Magic Tricks
//
//  Created by Ross on 13/08/2026.
//

import SwiftUI
import StoreKit

private let questionKey = L10nDomain("rateApp.question")
private let reactionKey = L10nDomain("rateApp.reaction")
private let dislikedKey = L10nDomain("rateApp.disliked")

struct RateAppSheet: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = RateAppViewModel()

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.phase {
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
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.phase)
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)

        .presentationDragIndicator(.visible)
        .modifier(RateAppPresentationModifier())
        .onDisappear { viewModel.markDismissed() }
    }

    // MARK: - Question

    private var questionView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(String(localized: questionKey("title")))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.textPrimary)
                Text(String(localized: questionKey("subtitle")))
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                reactionButton(
                    emoji: String(localized: reactionKey("likeIcon")),
                    label: String(localized: reactionKey("like")),
                    action: handleLike
                )
                reactionButton(
                    emoji: String(localized: reactionKey("dislikeIcon")),
                    label: String(localized: reactionKey("dislike")),
                    action: handleDislike
                )
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
                    .foregroundStyle(.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.cardBorder, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Disliked

    private var dislikedView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(String(localized: dislikedKey("icon")))
                    .font(.system(size: 44))
                Text(String(localized: dislikedKey("title")))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.textPrimary)
                Text(String(localized: dislikedKey("subtitle")))
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button(action: handleWriteToUs) {
                    Text(String(localized: dislikedKey("writeButton")))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryTrickButtonStyle(color: .buttonPrimary))

                Button(action: handleMaybeLater) {
                    Text(String(localized: dislikedKey("laterButton")))
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func handleLike() {
        dismiss()
        Task {
            try? await Task.sleep(milliseconds: 600)
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            else { return }
            SKStoreReviewController.requestReview(in: scene)
            viewModel.recordReviewShown()
        }
    }

    private func handleDislike() {
        withAnimation { viewModel.dislike() }
    }

    private func handleWriteToUs() {
        if let url = viewModel.writeToUs() {
            UIApplication.shared.open(url)
        }
        dismiss()
    }

    private func handleMaybeLater() {
        dismiss()
    }
}

// MARK: - Presentation modifier

private struct RateAppPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationDetents([.height(300)])
                .presentationBackground(Color.backgroundScreen)
                .presentationCornerRadius(28)
        } else if #available(iOS 16, *) {
            content
                .presentationDetents([.height(300)])
        } else {
            content
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            RateAppSheet()
                .environmentObject(AppFlowCoordinator(store: StoreManager()))
        }
}
