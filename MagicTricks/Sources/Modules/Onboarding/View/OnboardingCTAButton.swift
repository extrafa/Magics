import SwiftUI

struct OnboardingCTAButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ? Color.primaryText : Color.primaryText.opacity(0.3))
                .foregroundStyle(Color.background)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .animation(.easeOut(duration: 0.2), value: isEnabled)
        }
        .disabled(!isEnabled)
    }
}
