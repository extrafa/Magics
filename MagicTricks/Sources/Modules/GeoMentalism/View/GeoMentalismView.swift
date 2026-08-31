//
//  GeoMentalismView.swift
//  MagicTricks
//
//  Created by Ross on 29/07/2026.
//

import SwiftUI

struct GeoMentalismView: View {
    @State private var isVisible = AppPreferences.shared.isExitHintEnabled

    private var statusBarHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.top ?? 59
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                List {
                    ForEach(GeoMentalismCities.all, id: \.self) { city in
                        NavigationLink {
                            GeoMentalismCitiesView(city: city, isVisible: $isVisible)
                        } label: {
                            Text(city)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.primaryText)
                                .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.background)
                        .listRowSeparatorTint(Color.grayBorder)
                    }
                }
                .listStyle(.plain)
                .hideScrollContentBackground()

                ExitHintView(isVisible: $isVisible)
                    .padding(.top, statusBarHeight)
                    .ignoresSafeArea(edges: .top)
            }
            .navigationTitle(String(localized: "geo.list.title"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    GeoMentalismView()
}
