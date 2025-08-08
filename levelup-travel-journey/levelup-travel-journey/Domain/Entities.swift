//  Entities.swift
//  My Travel
//
//  NSManagedObject subclasses with convenience initializers.

import CoreData

@objc(Trip)
public class Trip: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trip> {
        NSFetchRequest<Trip>(entityName: "Trip")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var destination: String
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var notes: String?
    @NSManaged public var places: NSSet?
    @NSManaged public var expenses: NSSet?
    @NSManaged public var voiceNotes: NSSet?
}

extension Trip {
    static func create(in context: NSManagedObjectContext, id: UUID = UUID(), name: String, destination: String, startDate: Date, endDate: Date, notes: String? = nil) -> Trip {
        let obj = Trip(context: context)
        obj.id = id
        obj.name = name
        obj.destination = destination
        obj.startDate = startDate
        obj.endDate = endDate
        obj.notes = notes
        return obj
    }
}

@objc(Place)
public class Place: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Place> {
        NSFetchRequest<Place>(entityName: "Place")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var dayIndex: Int16
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var notes: String?

    @NSManaged public var trip: Trip
    @NSManaged public var voiceNotes: NSSet?
}

extension Place {
    static func create(in context: NSManagedObjectContext, id: UUID = UUID(), name: String, dayIndex: Int16, startTime: Date? = nil, endTime: Date? = nil, latitude: Double? = nil, longitude: Double? = nil, notes: String? = nil, trip: Trip) -> Place {
        let obj = Place(context: context)
        obj.id = id
        obj.name = name
        obj.dayIndex = dayIndex
        obj.startTime = startTime
        obj.endTime = endTime
        obj.latitude = latitude ?? 0
        obj.longitude = longitude ?? 0
        obj.notes = notes
        obj.trip = trip
        return obj
    }
}

@objc(Expense)
public class Expense: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        NSFetchRequest<Expense>(entityName: "Expense")
    }

    @NSManaged public var id: UUID
    @NSManaged public var amountTHB: NSDecimalNumber
    @NSManaged public var category: String
    @NSManaged public var note: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var originalAmount: NSDecimalNumber?
    @NSManaged public var originalCurrency: String?
    @NSManaged public var fxRateUsed: NSDecimalNumber?
    @NSManaged public var attachmentPath: String?

    @NSManaged public var trip: Trip
}

extension Expense {
    static func create(in context: NSManagedObjectContext, id: UUID = UUID(), amountTHB: Decimal, category: String, note: String? = nil, createdAt: Date = .init(), originalAmount: Decimal? = nil, originalCurrency: String? = nil, fxRateUsed: Decimal? = nil, attachmentPath: String? = nil, trip: Trip) -> Expense {
        let obj = Expense(context: context)
        obj.id = id
        obj.amountTHB = NSDecimalNumber(decimal: amountTHB)
        obj.category = category
        obj.note = note
        obj.createdAt = createdAt
        if let v = originalAmount { obj.originalAmount = NSDecimalNumber(decimal: v) }
        obj.originalCurrency = originalCurrency
        if let v = fxRateUsed { obj.fxRateUsed = NSDecimalNumber(decimal: v) }
        obj.attachmentPath = attachmentPath
        obj.trip = trip
        return obj
    }
}

@objc(VoiceNote)
public class VoiceNote: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<VoiceNote> {
        NSFetchRequest<VoiceNote>(entityName: "VoiceNote")
    }

    @NSManaged public var id: UUID
    @NSManaged public var audioPath: String
    @NSManaged public var transcript: String?
    @NSManaged public var language: String
    @NSManaged public var createdAt: Date
    @NSManaged public var status: String

    @NSManaged public var trip: Trip
    @NSManaged public var place: Place?
}

extension VoiceNote {
    enum Status: String { case recorded, transcribed }

    static func create(in context: NSManagedObjectContext, id: UUID = UUID(), audioPath: String, transcript: String? = nil, language: String, createdAt: Date = .init(), status: Status = .recorded, trip: Trip, place: Place? = nil) -> VoiceNote {
        let obj = VoiceNote(context: context)
        obj.id = id
        obj.audioPath = audioPath
        obj.transcript = transcript
        obj.language = language
        obj.createdAt = createdAt
        obj.status = status.rawValue
        obj.trip = trip
        obj.place = place
        return obj
    }
}

@objc(DataPack)
public class DataPack: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DataPack> {
        NSFetchRequest<DataPack>(entityName: "DataPack")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var version: String
    @NSManaged public var type: String
    @NSManaged public var filePath: String
    @NSManaged public var installedAt: Date
}

extension DataPack {
    enum PackType: String { case poi, map, asr, fx }

    static func create(in context: NSManagedObjectContext, id: UUID = UUID(), name: String, version: String, type: PackType, filePath: String, installedAt: Date = .init()) -> DataPack {
        let obj = DataPack(context: context)
        obj.id = id
        obj.name = name
        obj.version = version
        obj.type = type.rawValue
        obj.filePath = filePath
        obj.installedAt = installedAt
        return obj
    }
}
