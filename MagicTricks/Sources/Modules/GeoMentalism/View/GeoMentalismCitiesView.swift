//
//  GeoMentalismCitiesView.swift
//  MagicTricks
//
//  Created by Ross on 29/07/2026.
//

import SwiftUI

struct GeoMentalismCitiesView: View {
    @StateObject private var viewModel = GeoMentalismViewModel()
    let city: String
    @Binding var isVisible: Bool

    private static let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                LazyVGrid(columns: Self.columns, spacing: 12) {
                    ForEach(viewModel.displayedCities, id: \.self) { displayedCity in
                        CityCapsule(city: displayedCity)
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
            Task {
                try? await Task.sleep(milliseconds: 550)
                withAnimation(.easeInOut) {
                    viewModel.shuffleList()
                }
            }
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
                    .font(.system(size: 17, weight: .semibold))
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
    struct Preview: View {
        @State var isVisible = false
        var body: some View {
            NavigationStack {
                GeoMentalismCitiesView(city: "Barcelona", isVisible: $isVisible)
            }
            .environmentObject(StoreManager())
        }
    }
    return Preview()
}
