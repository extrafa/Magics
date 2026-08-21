//
//  GeoMentalismCities.swift
//  Magic Tricks
//
//  Created by Ross on 29/07/2026.
//

import Foundation

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
