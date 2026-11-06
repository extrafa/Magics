//
//  GeoMentalismViewModel.swift
//  MagicTricks
//
//  Created by Ross on 29/07/2026.
//

import Foundation

@MainActor
final class GeoMentalismViewModel: ObservableObject {

    @Published private(set) var displayedCities: [String] = []

    private static let otherCitiesCount = 9
    private static let maxCitiesPerLetter = 2
    private var generatedCity: String?

    func generateList(for city: String) {
        // The screen can appear again (after the paywall, say): keep the list the spectator already saw.
        guard generatedCity != city else { return }
        generatedCity = city

        let cityType = GeoMentalismCities.LetterType.of(city)
        
        let pool = switch cityType {
        case .straight:
            GeoMentalismCities.curved
        case .curved:
            GeoMentalismCities.straight
        }
        
        var generator = SystemRandomNumberGenerator()
        let others = GeoMentalismCities.balancedSample(
            from: pool,
            count: Self.otherCitiesCount,
            maxPerLetter: Self.maxCitiesPerLetter,
            using: &generator
        )
        displayedCities = (others + [city]).shuffled()
    }
    
    func shuffleList() {
        displayedCities.shuffle()
    }
}
