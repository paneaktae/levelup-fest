//  CoreDataStack.swift
//  My Travel
//
//  Purpose: Provide a lightweight Core Data stack (SQLite, WAL, auto-migration)
//

import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "levelup_travel_journey")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            // Enable automatic migration and WAL by default
            if let description = container.persistentStoreDescriptions.first {
                description.shouldInferMappingModelAutomatically = true
                description.shouldMigrateStoreAutomatically = true
                // Explicitly set WAL journaling (usually default, but ensure it)
                description.setOption(["journal_mode": "WAL"] as NSDictionary, forKey: NSSQLitePragmasOption)
            }
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var context: NSManagedObjectContext { container.viewContext }

    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        return ctx
    }

    func saveContext() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do { try context.save() } catch {
            assertionFailure("Failed saving context: \(error)")
        }
    }
}
