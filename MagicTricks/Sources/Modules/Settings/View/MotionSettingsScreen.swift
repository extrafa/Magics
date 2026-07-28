import SwiftUI

struct MotionSettingsScreen: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    MotionSettingsSection(
                        settings: settings,
                        copy: .motion,
                        resetAction: settings.resetMotionSettings
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(String(localized: "settings.motion.title"))
        .navigationBarTitleDisplayMode(.inline)
        .fontDesign(.rounded)
    }
}

#Preview {
    NavigationStack {
        MotionSettingsScreen()
            .environmentObject(SettingsStore())
    }
}
