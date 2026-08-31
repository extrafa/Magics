//
//  MotionSettingsScreen.swift
//  Magic Tricks
//
//  Created by Ross on 01/06/2026.
//

import SwiftUI

struct MotionSettingsScreen: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    MotionSettingsSection(settings: settings)
                    SettingsResetButton(action: settings.resetMotionSettings)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }
            .hideScrollIndicators()
        }
        .navigationTitle(String(localized: "settings.motion.title"))
        .navigationBarTitleDisplayMode(.inline)
        
    }
}

#Preview {
    NavigationStack {
        MotionSettingsScreen()
            .environmentObject(SettingsStore())
    }
}
