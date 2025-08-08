//  RepositoryCRUDTests.swift
//  levelup-travel-journeyTests
//
//  Basic CRUD tests for repositories.

import XCTest
@testable import levelup_travel_journey

final class RepositoryCRUDTests: XCTestCase {
    var tripRepo: TripRepository!
    var placeRepo: PlaceRepository!
    var expenseRepo: ExpenseRepository!
    var voiceRepo: VoiceNoteRepository!
    var packRepo: DataPackRepository!

    override func setUp() {
        super.setUp()
        tripRepo = CoreDataTripRepository()
        placeRepo = CoreDataPlaceRepository()
        expenseRepo = CoreDataExpenseRepository()
        voiceRepo = CoreDataVoiceNoteRepository()
        packRepo = CoreDataDataPackRepository()
    }

    func testTripPlaceExpenseVoicePackCRUD() throws {
        // Create Trip
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 3, to: start)!
        let trip = try tripRepo.create(name: "Test", destination: "Bangkok", startDate: start, endDate: end, notes: "note")

        // Place
        let place = try placeRepo.create(for: trip, name: "Temple", dayIndex: 0, startTime: nil, endTime: nil, latitude: 13.7563, longitude: 100.5018, notes: nil)
        XCTAssertEqual(place.trip.objectID, trip.objectID)

        // Expense
        let exp = try expenseRepo.create(for: trip, amountTHB: 100, category: "Food", note: nil, createdAt: Date(), originalAmount: nil, originalCurrency: nil, fxRateUsed: nil, attachmentPath: nil)
        XCTAssertEqual(exp.trip.objectID, trip.objectID)

        // Voice note
        let vn = try voiceRepo.create(for: trip, place: place, audioPath: "audio.m4a", transcript: nil, language: "th-TH", createdAt: Date(), status: .recorded)
        XCTAssertEqual(vn.trip.objectID, trip.objectID)
        XCTAssertEqual(vn.place?.objectID, place.objectID)

        // Data pack
        let pack = try packRepo.create(name: "POI-TH", version: "1.0", type: .poi, filePath: "/packs/poi-th.json", installedAt: Date())
        XCTAssertNotNil(pack.objectID)

        // Fetch
        let trips = try tripRepo.fetchAll()
        XCTAssertTrue(trips.contains(where: { $0.objectID == trip.objectID }))

        let places = try placeRepo.fetch(for: trip)
        XCTAssertTrue(places.contains(where: { $0.objectID == place.objectID }))

        let exps = try expenseRepo.fetch(for: trip)
        XCTAssertTrue(exps.contains(where: { $0.objectID == exp.objectID }))

        let notes = try voiceRepo.fetch(for: trip)
        XCTAssertTrue(notes.contains(where: { $0.objectID == vn.objectID }))

        let packs = try packRepo.fetchAll()
        XCTAssertTrue(packs.contains(where: { $0.objectID == pack.objectID }))

        // Delete
        try placeRepo.delete(place)
        try expenseRepo.delete(exp)
        try voiceRepo.delete(vn)
        try packRepo.delete(pack)
        try tripRepo.delete(trip)
    }
}
