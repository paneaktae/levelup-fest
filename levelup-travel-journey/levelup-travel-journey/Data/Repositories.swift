//  Repositories.swift
//  My Travel
//
//  Repository protocols and Core Data implementations for CRUD.

import CoreData

protocol TripRepository {
    func create(name: String, destination: String, startDate: Date, endDate: Date, notes: String?) throws -> Trip
    func fetchAll(search: String?) throws -> [Trip]
    func delete(_ trip: Trip) throws
}

protocol PlaceRepository {
    func create(for trip: Trip, name: String, dayIndex: Int16, startTime: Date?, endTime: Date?, latitude: Double?, longitude: Double?, notes: String?) throws -> Place
    func fetch(for trip: Trip, search: String?) throws -> [Place]
    func delete(_ place: Place) throws
}

protocol ExpenseRepository {
    func create(for trip: Trip, amountTHB: Decimal, category: String, note: String?, createdAt: Date, originalAmount: Decimal?, originalCurrency: String?, fxRateUsed: Decimal?, attachmentPath: String?) throws -> Expense
    func fetch(for trip: Trip, search: String?) throws -> [Expense]
    func delete(_ expense: Expense) throws
}

// Convenience overloads (no-search versions)
extension TripRepository {
    func fetchAll() throws -> [Trip] { try fetchAll(search: nil) }
}

extension PlaceRepository {
    func fetch(for trip: Trip) throws -> [Place] { try fetch(for: trip, search: nil) }
}

extension ExpenseRepository {
    func fetch(for trip: Trip) throws -> [Expense] { try fetch(for: trip, search: nil) }
}

protocol VoiceNoteRepository {
    func create(for trip: Trip, place: Place?, audioPath: String, transcript: String?, language: String, createdAt: Date, status: VoiceNote.Status) throws -> VoiceNote
    func fetch(for trip: Trip) throws -> [VoiceNote]
    func delete(_ note: VoiceNote) throws
}

protocol DataPackRepository {
    func create(name: String, version: String, type: DataPack.PackType, filePath: String, installedAt: Date) throws -> DataPack
    func fetchAll() throws -> [DataPack]
    func delete(_ pack: DataPack) throws
}

// MARK: - Implementations

final class CoreDataTripRepository: TripRepository {
    private let context: NSManagedObjectContext
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) { self.context = context }

    func create(name: String, destination: String, startDate: Date, endDate: Date, notes: String?) throws -> Trip {
        let bg = CoreDataStack.shared.newBackgroundContext()
        var objectID: NSManagedObjectID!
        try bg.performAndWait {
            let obj = Trip.create(in: bg, name: name, destination: destination, startDate: startDate, endDate: endDate, notes: notes)
            try bg.save()
            objectID = obj.objectID
        }
        return try context.existingObject(with: objectID) as! Trip
    }

    func fetchAll(search: String? = nil) throws -> [Trip] {
        let req: NSFetchRequest<Trip> = Trip.fetchRequest()
        if let q = search?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            req.predicate = NSPredicate(
                format: "(name CONTAINS[cd] %@) OR (destination CONTAINS[cd] %@) OR (notes CONTAINS[cd] %@)",
                q, q, q
            )
        }
        req.sortDescriptors = [NSSortDescriptor(key: #keyPath(Trip.startDate), ascending: true)]
        return try context.fetch(req)
    }

    func delete(_ trip: Trip) throws {
        let objectID = trip.objectID
        let bg = CoreDataStack.shared.newBackgroundContext()
        try bg.performAndWait {
            let obj = try bg.existingObject(with: objectID)
            bg.delete(obj)
            try bg.save()
        }
    }
}

final class CoreDataPlaceRepository: PlaceRepository {
    private let context: NSManagedObjectContext
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) { self.context = context }

    func create(for trip: Trip, name: String, dayIndex: Int16, startTime: Date?, endTime: Date?, latitude: Double?, longitude: Double?, notes: String?) throws -> Place {
        let bg = CoreDataStack.shared.newBackgroundContext()
        var objectID: NSManagedObjectID!
        try bg.performAndWait {
            let tripInBG = try bg.existingObject(with: trip.objectID) as! Trip
            // Create Place without assigning 'trip' directly to avoid setter issues
            let obj = Place(context: bg)
            obj.id = UUID()
            obj.name = name
            obj.dayIndex = dayIndex
            obj.startTime = startTime
            obj.endTime = endTime
            obj.latitude = latitude ?? 0
            obj.longitude = longitude ?? 0
            obj.notes = notes
            // Link via inverse to-many to avoid '-[Trip count]' on direct to-one set
            let placesSet = tripInBG.mutableSetValue(forKey: "places")
            placesSet.add(obj)
            try bg.save()
            objectID = obj.objectID
        }
        return try context.existingObject(with: objectID) as! Place
    }

    func fetch(for trip: Trip, search: String? = nil) throws -> [Place] {
        // Avoid predicate over relationship to sidestep rare SQL generator crashes.
        // Read via relationship then filter/sort in-memory.
        let tripInCtx = try context.existingObject(with: trip.objectID) as! Trip
        let set = (tripInCtx.places as? Set<Place>) ?? []
        var arr = Array(set)
        if let q = search?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            let qLower = q.lowercased()
            arr = arr.filter { p in
                let inName = p.name.lowercased().contains(qLower)
                let inNotes = p.notes?.lowercased().contains(qLower) ?? false
                return inName || inNotes
            }
        }
        arr.sort { (l, r) in
            if l.dayIndex != r.dayIndex { return l.dayIndex < r.dayIndex }
            let ls = l.startTime ?? .distantPast
            let rs = r.startTime ?? .distantPast
            return ls < rs
        }
        return arr
    }

    func delete(_ place: Place) throws {
        let objectID = place.objectID
        let bg = CoreDataStack.shared.newBackgroundContext()
        try bg.performAndWait {
            let obj = try bg.existingObject(with: objectID)
            bg.delete(obj)
            try bg.save()
        }
    }
}

final class CoreDataExpenseRepository: ExpenseRepository {
    private let context: NSManagedObjectContext
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) { self.context = context }

    func create(for trip: Trip, amountTHB: Decimal, category: String, note: String?, createdAt: Date = .init(), originalAmount: Decimal? = nil, originalCurrency: String? = nil, fxRateUsed: Decimal? = nil, attachmentPath: String? = nil) throws -> Expense {
        let bg = CoreDataStack.shared.newBackgroundContext()
        var objectID: NSManagedObjectID!
        try bg.performAndWait {
            let tripInBG = try bg.existingObject(with: trip.objectID) as! Trip
            // Create Expense without assigning 'trip' directly
            let obj = Expense(context: bg)
            obj.id = UUID()
            obj.amountTHB = NSDecimalNumber(decimal: amountTHB)
            obj.category = category
            obj.note = note
            obj.createdAt = createdAt
            if let v = originalAmount { obj.originalAmount = NSDecimalNumber(decimal: v) }
            obj.originalCurrency = originalCurrency
            if let v = fxRateUsed { obj.fxRateUsed = NSDecimalNumber(decimal: v) }
            obj.attachmentPath = attachmentPath
            // Link via inverse to-many
            let expensesSet = tripInBG.mutableSetValue(forKey: "expenses")
            expensesSet.add(obj)
            try bg.save()
            objectID = obj.objectID
        }
        return try context.existingObject(with: objectID) as! Expense
    }

    func fetch(for trip: Trip, search: String? = nil) throws -> [Expense] {
        // Read via relationship to avoid SQL generator crash
        let tripInCtx = try context.existingObject(with: trip.objectID) as! Trip
        let set = (tripInCtx.expenses as? Set<Expense>) ?? []
        var arr = Array(set)
        if let q = search?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            let qLower = q.lowercased()
            arr = arr.filter { e in
                let inCat = e.category.lowercased().contains(qLower)
                let inNote = e.note?.lowercased().contains(qLower) ?? false
                return inCat || inNote
            }
        }
        arr.sort { $0.createdAt > $1.createdAt }
        return arr
    }

    func delete(_ expense: Expense) throws {
        let objectID = expense.objectID
        let bg = CoreDataStack.shared.newBackgroundContext()
        try bg.performAndWait {
            let obj = try bg.existingObject(with: objectID)
            bg.delete(obj)
            try bg.save()
        }
    }
}

final class CoreDataVoiceNoteRepository: VoiceNoteRepository {
    private let context: NSManagedObjectContext
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) { self.context = context }

    func create(for trip: Trip, place: Place?, audioPath: String, transcript: String?, language: String, createdAt: Date = .init(), status: VoiceNote.Status = .recorded) throws -> VoiceNote {
        let bg = CoreDataStack.shared.newBackgroundContext()
        var objectID: NSManagedObjectID!
        try bg.performAndWait {
            let tripInBG = try bg.existingObject(with: trip.objectID) as! Trip
            let placeInBG: Place? = try place.map { try bg.existingObject(with: $0.objectID) as! Place }
            let obj = VoiceNote.create(in: bg, audioPath: audioPath, transcript: transcript, language: language, createdAt: createdAt, status: status, trip: tripInBG, place: placeInBG)
            try bg.save()
            objectID = obj.objectID
        }
        return try context.existingObject(with: objectID) as! VoiceNote
    }

    func fetch(for trip: Trip) throws -> [VoiceNote] {
        let req: NSFetchRequest<VoiceNote> = VoiceNote.fetchRequest()
        let tripInCtx = try context.existingObject(with: trip.objectID) as! Trip
        req.predicate = NSPredicate(format: "trip == %@", tripInCtx)
        req.sortDescriptors = [NSSortDescriptor(key: #keyPath(VoiceNote.createdAt), ascending: false)]
        return try context.fetch(req)
    }

    func delete(_ note: VoiceNote) throws {
        let objectID = note.objectID
        let bg = CoreDataStack.shared.newBackgroundContext()
        try bg.performAndWait {
            let obj = try bg.existingObject(with: objectID)
            bg.delete(obj)
            try bg.save()
        }
    }
}

final class CoreDataDataPackRepository: DataPackRepository {
    private let context: NSManagedObjectContext
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) { self.context = context }

    func create(name: String, version: String, type: DataPack.PackType, filePath: String, installedAt: Date = .init()) throws -> DataPack {
        let bg = CoreDataStack.shared.newBackgroundContext()
        var objectID: NSManagedObjectID!
        try bg.performAndWait {
            let obj = DataPack.create(in: bg, name: name, version: version, type: type, filePath: filePath, installedAt: installedAt)
            try bg.save()
            objectID = obj.objectID
        }
        return try context.existingObject(with: objectID) as! DataPack
    }

    func fetchAll() throws -> [DataPack] {
        let req: NSFetchRequest<DataPack> = DataPack.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: #keyPath(DataPack.installedAt), ascending: false)]
        return try context.fetch(req)
    }

    func delete(_ pack: DataPack) throws {
        let objectID = pack.objectID
        let bg = CoreDataStack.shared.newBackgroundContext()
        try bg.performAndWait {
            let obj = try bg.existingObject(with: objectID)
            bg.delete(obj)
            try bg.save()
        }
    }
}
