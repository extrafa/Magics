//
//  GeoMentalismViewModelTests.swift
//  MagicTricksTests
//

import UIKit
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

    func test_listSize_isWhatTheScreenAsksToReadOutLoud() {
        let viewModel = GeoMentalismViewModel()

        viewModel.generateList(for: straightCity)

        XCTAssertEqual(GeoMentalismViewModel.listSize, viewModel.displayedCities.count)
        XCTAssertEqual(GeoMentalismViewModel.listSize, 10)
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

        XCTAssertEqual(viewModel.displayedCities.count, 10)
        XCTAssertTrue(viewModel.displayedCities.contains(straightCity))
        let others = viewModel.displayedCities.filter { $0 != straightCity }
        XCTAssertTrue(others.allSatisfy { GeoMentalismCities.LetterType.of($0) == .curved })
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

// The window hears the system's shake and passes it on, so any screen can react to it.
@MainActor
final class DeviceShakeNotificationTests: XCTestCase {

    func test_aWindow_passesTheShakeOn_asItStartsEndsAndIsCancelled() {
        let window = UIWindow(frame: .zero)
        let began = expectation(forNotification: .deviceShakeBegan, object: nil)
        let ended = expectation(forNotification: .deviceShakeEnded, object: nil)
        let cancelled = expectation(forNotification: .deviceShakeCancelled, object: nil)

        window.motionBegan(.motionShake, with: nil)
        window.motionEnded(.motionShake, with: nil)
        window.motionCancelled(.motionShake, with: nil)

        wait(for: [began, ended, cancelled], timeout: 1)
    }

    func test_aMotionThatIsNotAShake_isNotPassedOn() {
        let window = UIWindow(frame: .zero)
        let began = expectation(forNotification: .deviceShakeBegan, object: nil)
        let ended = expectation(forNotification: .deviceShakeEnded, object: nil)
        let cancelled = expectation(forNotification: .deviceShakeCancelled, object: nil)
        [began, ended, cancelled].forEach { $0.isInverted = true }

        window.motionBegan(.none, with: nil)
        window.motionEnded(.none, with: nil)
        window.motionCancelled(.none, with: nil)

        wait(for: [began, ended, cancelled], timeout: 0.3)
    }
}

