//
//  RateAppViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 01/09/2026.
//

import Foundation

@MainActor
final class RateAppViewModel: ObservableObject {

    enum Phase {
        case question
        case disliked
    }

    @Published private(set) var phase: Phase = .question

    private var preferences: RateAppPreferenceManaging

    init(preferences: RateAppPreferenceManaging = AppPreferences.shared) {
        self.preferences = preferences
    }

    func recordReviewShown() {
        preferences.hasRespondedToRating = true
    }

    func dislike() {
        phase = .disliked
    }

    func writeToUs() -> URL? {
        preferences.hasRespondedToRating = true
        return AppConfig.supportMailURL(subject: String(localized: "rateApp.feedback.emailSubject"))
    }

    // The sheet shows once: whatever the person does with it, it doesn't come back.
    func markDismissed() {
        preferences.hasRespondedToRating = true
    }
}
