//
//  GeoMentalismCities.swift
//  Magic Tricks
//
//  Created by Ross on 29/07/2026.
//

import Foundation

enum LetterType {
    case straight
    case curved

    private static let straightLetters: Set<Character> =
        ["A","E","F","H","I","K","L","M","N","T","V","W","X","Y","Z"]

    static func of(_ city: String) -> LetterType {
        guard let first = city.uppercased().first else { return .straight }
        return straightLetters.contains(first) ? .straight : .curved
    }
}

enum GeoMentalismCities {
    static let straight: [String] = [
        "Abu Dhabi", "Athens", "Hong Kong",
        "Istanbul", "Lisbon", "London",
        "Los Angeles", "Manchester", "Manila",
        "Medellin", "Melbourne", "Mexico City",
        "Miami", "Milan", "Minneapolis",
        "Montreal", "Nairobi", "Naples", "New York"
    ]

    static let curved: [String] = [
        "Barcelona", "Beijing", "Boston",
        "Brighton", "Bristol", "Calcutta",
        "Chicago", "Delhi", "Osaka",
        "Paris", "Rio de Janeiro", "Rome", "Rotterdam",
        "Salvador", "San Francisco", "São Paulo", "Seoul"
    ]

    static let all: [String] = (straight + curved).sorted()
}
