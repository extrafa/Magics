import SwiftUI

struct OBSolutionScreen: View {
    let solutions: [OnboardingPainPoint]
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(localized: "onboarding.solution.headline"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)
                        .padding(.bottom, 8)

                    ForEach(solutions) { pain in
                        solutionRow(pain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }

            OnboardingCTAButton(
                title: String(localized: "onboarding.cta.continue"),
                action: onContinue
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func solutionRow(_ pain: OnboardingPainPoint) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.primaryText)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(pain.localizedTitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(pain.localizedSolution)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.primaryText)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.grayCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.grayBorder, lineWidth: 1)
                )
        )
    }
}
