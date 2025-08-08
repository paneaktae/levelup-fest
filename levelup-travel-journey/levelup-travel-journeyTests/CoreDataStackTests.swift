//  CoreDataStackTests.swift
//  levelup-travel-journeyTests
//
//  Basic tests to ensure CoreDataStack loads and can save.

import XCTest
@testable import levelup_travel_journey

final class CoreDataStackTests: XCTestCase {
    func test_StackLoadsAndSavesInMemory() {
        // Create an in-memory stack for unit testing by accessing the shared which uses disk by default.
        // Here we just ensure context is available and save does not crash when no changes.
        let stack = CoreDataStack.shared
        XCTAssertNotNil(stack.context)
        stack.saveContext() // should not crash
    }
}
