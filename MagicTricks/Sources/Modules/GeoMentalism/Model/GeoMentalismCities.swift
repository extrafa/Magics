//
//  GeoMentalismCities.swift
//  Magic Tricks
//
//  Created by Ross on 29/07/2026.
//

import Foundation

enum GeoMentalismCities {
    enum LetterType {
        case straight
        case curved

        private static let straightLetters: Set<Character> =
            ["A", "E", "F", "H", "I", "K", "L", "M", "N", "T", "V", "W", "X", "Y", "Z"]

        static func of(_ city: String) -> LetterType {
            guard let first = city.uppercased().first else { return .straight }
            return straightLetters.contains(first) ? .straight : .curved
        }
    }

    static let all: [String] = [
        "Abu Dhabi", "Athens", "Barcelona", "Beijing", "Boston",
        "Brighton", "Bristol", "Calcutta", "Chicago", "Delhi",
        "Hong Kong", "Istanbul", "Lisbon", "London", "Los Angeles",
        "Manchester", "Manila", "Medellin", "Melbourne", "Mexico City",
        "Miami", "Milan", "Minneapolis", "Montreal", "Nairobi",
        "Naples", "New York", "Osaka", "Paris", "Rio de Janeiro",
        "Rome", "Rotterdam", "Salvador", "San Francisco", "São Paulo", "Seoul"
    ]

    static let straight: [String] = all.filter { LetterType.of($0) == .straight }
    static let curved: [String] = all.filter { LetterType.of($0) == .curved }
}
