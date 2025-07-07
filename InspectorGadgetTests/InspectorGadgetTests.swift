//
//  InspectorGadgetTests.swift
//  InspectorGadgetTests
//
//  Created by Aaron Cleveland on 7/6/25.
//

import XCTest
@testable import InspectorGadget
import SwiftUI

final class InspectorGadgetTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testOverlayWindowSingleton() {
        // Test that the OverlayWindow singleton exists
        let window = OverlayWindow.shared
        XCTAssertNotNil(window, "OverlayWindow.shared should not be nil")
    }

    func testOverlayWindowLabelUpdate() {
        // Test that updating the label changes its text (using test-only accessor)
        let window = OverlayWindow.shared
        let testText = "Hello, Inspector!"
        window.updateText(testText)
        // Wait briefly for async update
        let expectation = XCTestExpectation(description: "Wait for label update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(window.test_labelText, testText, "OverlayWindow label should update text")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testInspectorGadgetCoreStart() {
        // Test that starting InspectorGadgetCore does not crash
        XCTAssertNoThrow(InspectorGadgetCore.start(), "InspectorGadgetCore.start() should not throw or crash")
    }

    func testInspectorGadgetModifierConstruction() {
        // Test that the SwiftUI modifier can be constructed
        let modifier = InspectorGadgetModifier()
        // Just check that it exists
        XCTAssertNotNil(modifier)
    }

}
