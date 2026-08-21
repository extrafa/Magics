//
//  GeoMentalismViewModel.swift
//  MagicTricks
//
//  Created by Ross on 29/07/2026.
//

import Foundation

@MainActor
final class GeoMentalismViewModel: ObservableObject {

    private enum LetterType {
        case straight
        case curved

        private static let straightLetters: Set<Character> =
            ["A","E","F","H","I","K","L","M","N","T","V","W","X","Y","Z"]

        static func of(_ city: String) -> LetterType {
            guard let first = city.uppercased().first else { return .straight }
            return straightLetters.contains(first) ? .straight : .curved
        }
    }
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
