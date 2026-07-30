//
//  GeoMentalismViewModel.swift
//  MagicTricks
//
//  Created by Ross on 29/07/2026.
//

import Foundation

@MainActor
final class GeoMentalismViewModel: ObservableObject {
    @Published var displayedCities: [String] = []
    
    func generateList(for city: String) {
        let cityType = LetterType.of(city)
        
        let pool = switch cityType {
        case .straight:
            GeoMentalismCities.curved
        case .curved:
            GeoMentalismCities.straight
        }
        
        let nine = Array(pool.shuffled().prefix(9))
        displayedCities = (nine + [city]).shuffled()
    }
    
    func shuffleList() {
        displayedCities.shuffle()
    }
}
