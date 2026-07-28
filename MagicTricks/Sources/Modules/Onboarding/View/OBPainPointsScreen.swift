import SwiftUI

struct OBPainPointsScreen: View {
    @Binding var selectedPainPoints: Set<OnboardingPainPoint>
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "onboarding.pain.headline"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)
                        .padding(.bottom, 4)

                    Text(String(localized: "onboarding.pain.subheadline"))
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 20)

                    ForEach(OnboardingPainPoint.allCases) { pain in
                        OBOptionRow(
                            emoji: pain.emoji,
                            title: pain.localizedTitle,
                            isSelected: selectedPainPoints.contains(pain),
                            isMultiSelect: true
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .onTapGesture {
                            if selectedPainPoints.contains(pain) {
                                selectedPainPoints.remove(pain)
                            } else {
                                selectedPainPoints.insert(pain)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }

            OnboardingCTAButton(
                title: String(localized: "onboarding.cta.continue"),
                isEnabled: !selectedPainPoints.isEmpty,
                action: onContinue
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
