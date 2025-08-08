//  CoreDataStackMVPTests.swift
//  levelup-travel-journeyTests
//
//  Ensures CoreDataStack loads with the existing model name.

import XCTest
@testable import levelup_travel_journey

final class CoreDataStackMVPTests: XCTestCase {
    func test_CoreDataStackLoads() {
        let ctx = CoreDataStack.shared.context
        XCTAssertNotNil(ctx)
    }
}
