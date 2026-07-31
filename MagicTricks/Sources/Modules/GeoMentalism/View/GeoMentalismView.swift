//
//  GeoMentalismView.swift
//  MagicTricks
//
//  Created by Ross on 29/07/2026.
//

import SwiftUI

struct GeoMentalismView: View {
    @State var isVisible = true

    private var statusBarHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.top ?? 59
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                List {
                    ForEach(GeoMentalismCities.all, id: \.self) { city in
                        NavigationLink(value: city) {
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
                .scrollContentBackground(.hidden)
                .navigationDestination(for: String.self) { city in
                    GeoMentalismCitiesView(city: city, isVisible: $isVisible)
                }

                ExitHintView(isVisible: $isVisible)
                    .padding(.top, statusBarHeight)
                    .ignoresSafeArea(edges: .top)
            }
            .navigationTitle(String(localized: "geo.list.title"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct GeoMentalismCitiesView: View {
    @StateObject private var viewModel = GeoMentalismViewModel()
    let city: String
    @Binding var isVisible: Bool

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.displayedCities, id: \.self) { city in
                        CityCapsule(city: city)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer()
            }

            shuffleButton
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                WatermarkView()
            }
        }
        .onAppear {
            isVisible = false
            viewModel.generateList(for: city)
        }
    }

    private var shuffleButton: some View {
        Button {
            withAnimation(.easeInOut) {
                viewModel.shuffleList()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "shuffle")
                    .fontWeight(.semibold)
                Text(String(localized: "geo.shuffle"))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.button)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
}

#Preview {
    GeoMentalismView()
}
