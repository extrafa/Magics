//
//  GeoMentalismView.swift
//  MagicTricks
//
//  Created by Ross on 29/07/2026.
//

import SwiftUI

struct GeoMentalismView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = true
    var body: some View {
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
                GeoMentalismCitiesView(city: city)
            }
            
            ExitHintView(isVisible: $isVisible)
        }
        .navigationTitle(String(localized: "geo.list.title"))
        .navigationBarTitleDisplayMode(.large)
    }
}

struct GeoMentalismCitiesView: View {
    @StateObject private var viewModel = GeoMentalismViewModel()
    let city: String

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.displayedCities, id: \.self) { city in
                        CityCapsule(city: city)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }

            shuffleButton
        }
        .onAppear {
            viewModel.generateList(for: city)
        }
    }

    private var shuffleButton: some View {
        Button(action: viewModel.shuffleList) {
            HStack(spacing: 8) {
                Image(systemName: "shuffle")
                    .fontWeight(.semibold)
                Text(String(localized: "geo.shuffle"))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
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
