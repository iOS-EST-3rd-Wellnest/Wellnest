//
//  CoreDataStack.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/16/25.
//

import CoreData

public final class CoreDataStack {
    public static let shared = CoreDataStack()
    private init() {}

    public lazy var container: NSPersistentContainer = {
        let c = NSPersistentContainer(name: "Wellnest")
        c.loadPersistentStores { _, error in
            if let error = error { fatalError("Core Data load error: \(error)") }
        }
        c.viewContext.automaticallyMergesChangesFromParent = true
        c.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return c
    }()

    public var viewContext: NSManagedObjectContext { container.viewContext }

    @discardableResult
    public func saveViewContextIfNeeded() throws -> Bool {
        guard viewContext.hasChanges else { return false }
        try viewContext.save()
        return true
    }
}
