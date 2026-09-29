//
//  CalculatorPredictionViewModelTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class CalculatorPredictionViewModelTests: XCTestCase {

    func test_appendDecimal_afterOperatorFollowingDecimalNumber_startsNewDecimalNumber() {
        let vm = CalculatorPredictionViewModel()

        vm.buttonPressed(.five)
        vm.buttonPressed(.decimal)
        vm.buttonPressed(.five)
        vm.buttonPressed(.add)
        vm.buttonPressed(.decimal)

        XCTAssertTrue(vm.display.hasSuffix(","), "decimal after the operator should be accepted, not silently dropped")
    }

    func test_decimalAfterOperator_evaluatesAsANewNumber() {
        let vm = CalculatorPredictionViewModel()

        vm.buttonPressed(.five)
        vm.buttonPressed(.decimal)
        vm.buttonPressed(.five)
        vm.buttonPressed(.add)
        vm.buttonPressed(.decimal)
        vm.buttonPressed(.five)
        vm.buttonPressed(.equal)

        XCTAssertEqual(vm.display, "6")
    }
}
