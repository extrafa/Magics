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
    private static let snoozeDurationDays = 14

    init(preferences: RateAppPreferenceManaging = AppPreferences.shared) {
        self.preferences = preferences
    }

    func like() {
        preferences.hasRespondedToRating = true
    }

    func dislike() {
        phase = .disliked
    }

    func writeToUs() -> URL? {
        preferences.hasRespondedToRating = true
        return AppConfig.supportMailURL(subject: "Magic Tricks Feedback")
    }

    func markDismissed() {
        preferences.ratingSnoozedUntil = Calendar.current.date(
            byAdding: .day,
            value: Self.snoozeDurationDays,
            to: Date()
        )
    }
}
