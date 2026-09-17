//
//  InstructionModelsTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

final class InstructionModelsTests: XCTestCase {

    func test_instructionStep_withSameContent_isEqual() {
        let a = InstructionStep(title: "Step 1", description: "Do the thing", phase: .preparation)
        let b = InstructionStep(title: "Step 1", description: "Do the thing", phase: .preparation)

        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func test_instructionStep_idMatchesTitle() {
        let step = InstructionStep(title: "Step 1", description: "Do the thing", phase: .preparation)

        XCTAssertEqual(step.id, "Step 1")
    }
}
