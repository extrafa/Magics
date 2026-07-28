import SwiftUI

struct OBGoalScreen: View {
    @Binding var selectedGoal: OnboardingGoal?
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "onboarding.goal.headline"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)
                        .padding(.bottom, 4)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.06), value: appeared)

                    Text(String(localized: "onboarding.goal.subheadline"))
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.14), value: appeared)

                    ForEach(Array(OnboardingGoal.allCases.enumerated()), id: \.element) { i, goal in
                        OBOptionRow(
                            emoji: goal.emoji,
                            title: goal.localizedTitle,
                            isSelected: selectedGoal == goal,
                            isMultiSelect: false
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .onTapGesture { selectedGoal = goal }
                        .padding(.bottom, 8)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.82).delay(0.2 + Double(i) * 0.05),
                            value: appeared
                        )
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { appeared = true }
        }
    }

    private var ctaButton: some View {
        OnboardingCTAButton(
            title: String(localized: "onboarding.cta.continue"),
            isEnabled: selectedGoal != nil,
            action: onContinue
        )
    }
}
