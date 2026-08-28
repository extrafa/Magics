//
//  CalculatorPredictionEngineTests.swift
//  MagicTricksTests
//
//  Created by Ross on 28/08/2026.
//

import XCTest
@testable import MagicTricks

final class CalculatorPredictionEngineTests: XCTestCase {

    private let engine = CalculatorPredictionEngine()

    func test_evaluate_respectsOperatorPrecedence() throws {
        XCTAssertEqual(try engine.evaluate("2+2×2"), 6)
    }

    func test_evaluate_supportsUnaryMinus() throws {
        XCTAssertEqual(try engine.evaluate("-3×-3"), 9)
    }

    func test_evaluate_divisionByZeroThrows() {
        XCTAssertThrowsError(try engine.evaluate("5÷0"))
    }

    func test_evaluate_moduloReturnsRemainder() throws {
        XCTAssertEqual(try engine.evaluate("7%3"), 1)
    }

    func test_evaluate_garbageInputThrows() {
        XCTAssertThrowsError(try engine.evaluate("2++"))
        XCTAssertThrowsError(try engine.evaluate(".."))
        XCTAssertThrowsError(try engine.evaluate(""))
    }

    func test_evaluate_normalizesDisplaySymbols() throws {
        XCTAssertEqual(try engine.evaluate("4×2"), 8)
        XCTAssertEqual(try engine.evaluate("4÷2"), 2)
        XCTAssertEqual(try engine.evaluate("5−2"), 3)
        XCTAssertEqual(try engine.evaluate("2,5+2,5"), 5)
    }

    func test_evaluate_deeplyNestedUnaryMinus_resolvesCorrectSign() throws {
        // Not testing the actual stack limit — overflow crashes the process, doesn't throw.
        let evenDepth = String(repeating: "-", count: 100) + "3"
        let oddDepth = String(repeating: "-", count: 101) + "3"

        XCTAssertEqual(try engine.evaluate(evenDepth), 3)
        XCTAssertEqual(try engine.evaluate(oddDepth), -3)
    }
}
