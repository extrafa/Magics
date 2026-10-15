//
//  GeoMentalismViewModelTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class GeoMentalismViewModelTests: XCTestCase {

    private let straightCity = "Manchester"
    private let curvedCity = "Rotterdam"

    func test_balancedSample_neverTakesMoreThanTwoCitiesPerLetter() {
        var generator = SystemRandomNumberGenerator()
        for pool in [GeoMentalismCities.straight, GeoMentalismCities.curved] {
            for _ in 0..<300 {
                let sample = GeoMentalismCities.balancedSample(from: pool, count: 9, maxPerLetter: 2, using: &generator)

                let perLetter = Dictionary(grouping: sample, by: { $0.uppercased().first! }).mapValues(\.count)
                XCTAssertLessThanOrEqual(perLetter.values.max() ?? 0, 2)
            }
        }
    }

    func test_balancedSample_returnsTheRequestedNumberOfDistinctCitiesFromThePool() {
        var generator = SystemRandomNumberGenerator()

        let sample = GeoMentalismCities.balancedSample(from: GeoMentalismCities.straight, count: 9, maxPerLetter: 2, using: &generator)

        XCTAssertEqual(sample.count, 9)
        XCTAssertEqual(Set(sample).count, 9)
        XCTAssertTrue(Set(sample).isSubset(of: Set(GeoMentalismCities.straight)))
    }

    func test_balancedSample_withAPoolTooSmallForTheCap_stillFillsTheList() {
        var generator = SystemRandomNumberGenerator()
        let pool = ["Madrid", "Milan", "Moscow", "Malaga"]

        let sample = GeoMentalismCities.balancedSample(from: pool, count: 4, maxPerLetter: 2, using: &generator)

        XCTAssertEqual(Set(sample), Set(pool))
    }

    func test_generateList_forAStraightCity_showsItWithNineCurvedCities() {
        let viewModel = GeoMentalismViewModel()

        viewModel.generateList(for: straightCity)

        XCTAssertEqual(viewModel.displayedCities.count, 10)
        XCTAssertTrue(viewModel.displayedCities.contains(straightCity))
        let others = viewModel.displayedCities.filter { $0 != straightCity }
        XCTAssertTrue(others.allSatisfy { GeoMentalismCities.LetterType.of($0) == .curved })
    }

    func test_generateList_forACurvedCity_showsItWithNineStraightCities() {
        let viewModel = GeoMentalismViewModel()

        viewModel.generateList(for: curvedCity)

        XCTAssertEqual(viewModel.displayedCities.count, 10)
        XCTAssertTrue(viewModel.displayedCities.contains(curvedCity))
        let others = viewModel.displayedCities.filter { $0 != curvedCity }
        XCTAssertTrue(others.allSatisfy { GeoMentalismCities.LetterType.of($0) == .straight })
    }

    func test_generateList_whenTheScreenAppearsAgainForTheSameCity_keepsTheList() {
        let viewModel = GeoMentalismViewModel()
        viewModel.generateList(for: curvedCity)
        let first = viewModel.displayedCities

        for _ in 0..<20 { viewModel.generateList(for: curvedCity) }

        XCTAssertEqual(viewModel.displayedCities, first)
    }

    func test_generateList_forADifferentCity_buildsAListForThatCity() {
        let viewModel = GeoMentalismViewModel()
        viewModel.generateList(for: curvedCity)

        viewModel.generateList(for: straightCity)

        XCTAssertTrue(viewModel.displayedCities.contains(straightCity))
        XCTAssertFalse(viewModel.displayedCities.contains(curvedCity))
    }

    func test_shuffleList_keepsTheSameCities() {
        let viewModel = GeoMentalismViewModel()
        viewModel.generateList(for: curvedCity)
        let before = Set(viewModel.displayedCities)

        viewModel.shuffleList()

        XCTAssertEqual(Set(viewModel.displayedCities), before)
        XCTAssertEqual(viewModel.displayedCities.count, 10)
    }
}
