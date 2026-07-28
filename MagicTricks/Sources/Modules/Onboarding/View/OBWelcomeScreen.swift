import SwiftUI

struct OBWelcomeScreen: View {
    let onContinue: () -> Void

    @State private var appeared = false

    private let topRow: [(String, Color)] = [
        ("paintpalette",             TrickPalette.Collection.colorSense),
        ("pawprint.fill",            TrickPalette.Collection.mindPattern),
        ("ipad",                     TrickPalette.Collection.calculatorPrediction),
    ]

    private let bottomRow: [(String, Color)] = [
        ("stopwatch.fill",            TrickPalette.Collection.timeControl),
        ("photo.on.rectangle.angled", TrickPalette.Collection.magicGallery),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            trickPreview
                .padding(.bottom, 44)

            VStack(spacing: 12) {
                Text(String(localized: "onboarding.welcome.headline"))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.42), value: appeared)

                Text(String(localized: "onboarding.welcome.subheadline"))
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.52), value: appeared)
            }

            Spacer()

            OnboardingCTAButton(
                title: String(localized: "onboarding.welcome.cta"),
                action: onContinue
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.35).delay(0.65), value: appeared)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { appeared = true }
        }
    }

    private var trickPreview: some View {
        VStack(spacing: 18) {
            HStack(spacing: 18) {
                ForEach(topRow.indices, id: \.self) { i in
                    let (icon, color) = topRow[i]
                    TrickIcon(systemName: icon, color: color, size: CGSize(width: 64, height: 64))
                        .floatingMotion(
                            phase: Double(i) * 0.38,
                            travel: 2.8,
                            rotation: 0.75,
                            duration: 4.1 + Double(i) * 0.3
                        )
                        .scaleEffect(appeared ? 1 : 0.4)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.65).delay(Double(i) * 0.07),
                            value: appeared
                        )
                }
            }

            HStack(spacing: 18) {
                ForEach(bottomRow.indices, id: \.self) { i in
                    let (icon, color) = bottomRow[i]
                    TrickIcon(systemName: icon, color: color, size: CGSize(width: 64, height: 64))
                        .floatingMotion(
                            phase: Double(i + 3) * 0.38,
                            travel: 2.8,
                            rotation: 0.75,
                            duration: 4.4 + Double(i) * 0.3
                        )
                        .scaleEffect(appeared ? 1 : 0.4)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.65).delay(Double(i + 3) * 0.07),
                            value: appeared
                        )
                }
            }
        }
        .fontDesign(.rounded)
    }
}

#Preview {
    OBWelcomeScreen(onContinue: {})
        .background(Color.background)
}
