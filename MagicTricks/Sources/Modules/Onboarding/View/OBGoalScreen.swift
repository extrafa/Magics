//
//  OBGoalScreen.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import SwiftUI

struct OBGoalScreen: View {
    @Binding var selectedGoals: Set<OnboardingGoal>
    let onContinue: () -> Void

    @State private var appeared = false

    private var isEverywhereActive: Bool {
        selectedGoals.contains(.everywhere)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "onboarding.goal.headline"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)
                        .padding(.bottom, 4)
                        .onboardingAppear(appeared, offset: 14, delay: 0.06)

                    Text(String(localized: "onboarding.goal.subheadline"))
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 20)
                        .onboardingAppear(appeared, offset: 10, delay: 0.14)

                    ForEach(Array(OnboardingGoal.allCases.enumerated()), id: \.element) { i, goal in
                        let isSelected = goal == .everywhere
                            ? isEverywhereActive
                            : !isEverywhereActive && selectedGoals.contains(goal)

                        OBOptionRow(
                            emoji: goal.emoji,
                            title: goal.localizedTitle,
                            isSelected: isSelected
                        )
                        .opacity(isEverywhereActive && goal != .everywhere ? 0.42 : 1.0)
                        .animation(.easeOut(duration: 0.22), value: isEverywhereActive)
                        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .onTapGesture { handleTap(goal) }
                        .padding(.bottom, 8)
                        .onboardingAppear(appeared, offset: 12, delay: 0.2 + Double(i) * 0.05)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }

            ctaButton
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.5), value: appeared)
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(milliseconds: 240)
                appeared = true
            }
        }
    }

    private func handleTap(_ goal: OnboardingGoal) {
        withAnimation(.easeOut(duration: 0.2)) {
            if goal == .everywhere {
                selectedGoals = isEverywhereActive ? [] : Set(OnboardingGoal.allCases)
            } else if isEverywhereActive {
                selectedGoals.remove(goal)
                selectedGoals.remove(.everywhere)
            } else if selectedGoals.contains(goal) {
                selectedGoals.remove(goal)
            } else {
                selectedGoals.insert(goal)
                let allFour: Set<OnboardingGoal> = [.parties, .dates, .work, .family]
                if selectedGoals.isSuperset(of: allFour) {
                    selectedGoals = Set(OnboardingGoal.allCases)
                }
            }
        }
    }

    private var ctaButton: some View {
        OnboardingCTAButton(
            title: String(localized: "onboarding.cta.continue"),
            isEnabled: !selectedGoals.isEmpty,
            action: onContinue
        )
    }
}
