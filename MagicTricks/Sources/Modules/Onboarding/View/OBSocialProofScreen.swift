import SwiftUI

private struct Testimonial {
    let body: String
    let name: String
    let tag: String
}

struct OBSocialProofScreen: View {
    let onContinue: () -> Void

    private let testimonials: [Testimonial] = [
        Testimonial(
            body: String(localized: "onboarding.proof.review1.body"),
            name: String(localized: "onboarding.proof.review1.name"),
            tag: String(localized: "onboarding.proof.review1.tag")
        ),
        Testimonial(
            body: String(localized: "onboarding.proof.review2.body"),
            name: String(localized: "onboarding.proof.review2.name"),
            tag: String(localized: "onboarding.proof.review2.tag")
        ),
        Testimonial(
            body: String(localized: "onboarding.proof.review3.body"),
            name: String(localized: "onboarding.proof.review3.name"),
            tag: String(localized: "onboarding.proof.review3.tag")
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(localized: "onboarding.proof.headline"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)
                        .padding(.bottom, 8)

                    ForEach(testimonials.indices, id: \.self) { i in
                        testimonialCard(testimonials[i])
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

    private func testimonialCard(_ t: Testimonial) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.orange)
                }
            }

            Text("\u{201C}\(t.body)\u{201D}")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.primaryText)
                .lineSpacing(3)

            HStack(spacing: 8) {
                Text(t.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primaryText)

                Text("·")
                    .foregroundStyle(.secondary)

                Text(t.tag)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
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
