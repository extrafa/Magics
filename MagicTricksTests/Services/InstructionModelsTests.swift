//
//  InstructionModelsTests.swift
//  MagicTricksTests
//

import XCTest
import UIKit
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

    func test_allInstructionSteps_imageNamesExistInAssetCatalog() {
        let instructions: [Instruction] = [
            .calculatorPrediction, .colorSense, .geoMentalism,
            .magicGallery, .phantomDraw, .timeControl
        ]
        for instruction in instructions {
            for step in instruction.steps {
                guard let imageName = step.imageName else { continue }
                XCTAssertNotNil(
                    UIImage(named: imageName),
                    "\(instruction.trickType) step \"\(step.title)\" references missing asset \"\(imageName)\""
                )
            }
        }
    }
}
