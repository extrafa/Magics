import SwiftUI

struct OBFirstScreen: View {
    let solutions: [OnboardingPainPoint]
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Step-by-step instructions for every trick.")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primaryText)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            Spacer()
            
            Image("instruction")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 500)

            
            Spacer()
            
            OnboardingCTAButton(
                title: String(localized: "onboarding.cta.continue"),
                action: onContinue
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
