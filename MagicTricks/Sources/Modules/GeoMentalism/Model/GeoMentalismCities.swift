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

    // Picks `count` distinct cities with at most `maxPerLetter` sharing a first letter, so the list doesn't look lopsided
    // (nine of the straight cities start with M).
    static func balancedSample<G: RandomNumberGenerator>(
        from pool: [String],
        count: Int,
        maxPerLetter: Int,
        using generator: inout G
    ) -> [String] {
        var picked: [String] = []
        var skipped: [String] = []
        var perLetter: [Character: Int] = [:]
        for city in pool.shuffled(using: &generator) {
            let letter = city.uppercased().first ?? " "
            if perLetter[letter, default: 0] < maxPerLetter {
                perLetter[letter, default: 0] += 1
                picked.append(city)
            } else {
                skipped.append(city)
            }
            if picked.count == count { return picked }
        }
        // A pool too small for the cap still has to fill the list.
        return picked + skipped.prefix(count - picked.count)
    }
}
