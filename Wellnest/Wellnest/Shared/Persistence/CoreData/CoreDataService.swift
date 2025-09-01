//
//  CoreDataService.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import Foundation
import CoreData

final class CoreDataService {

    // MARK: - Singleton
    static let shared = CoreDataService()

    private let logger: CrashLogger

    private init(logger: CrashLogger = CrashlyticsLogger()) {
        self.logger = logger
    }

    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Wellnest")
        container.loadPersistentStores { [weak self] (_, error) in
            guard let self else { return }
            if let error = error as NSError? {
                self.logger.record(error, userInfo: [
                    "phase": "loadPersistentStores",
                    "store": name
                ])
                fatalError("error \(error), \(error.userInfo)")
            } else {
                self.logger.log("CoreData: persistent stores loaded")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Save Context
    func saveContext() throws {
        if context.hasChanges {
            do {
                try context.save()
                logger.log("CoreData: saveContext success")
            } catch {
                let nserror = error as NSError
                logger.record(nserror, userInfo: [
                    "phase": "saveContext",
                    "mergePolicy": String(describing: context.mergePolicy)
                ])
                throw CoreDataError.saveError(error)
            }
        }
    }
}

extension CoreDataService {

    func create<Entity>(_ type: Entity.Type) -> Entity where Entity: NSManagedObject {
        let entityName = String(describing: type)
        guard let entity = NSEntityDescription.insertNewObject(
            forEntityName: entityName,
            into: context
        ) as? Entity else {
            let err = NSError(domain: "CoreDataService", code: 9701,
                             userInfo: [NSLocalizedDescriptionKey: "Failed to create entity \(entityName)"])
            logger.record(err, userInfo: ["phase": "create", "entity": entityName])
            fatalError("Failed to create entity \(entityName)")
        }
        logger.log("CoreData: create \(entityName)")
        return entity
    }

    func fetch<Entity>(
        _ type: Entity.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) throws -> [Entity] where Entity: NSManagedObject {
        let request = NSFetchRequest<Entity>(entityName: String(describing: Entity.self))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        do {
            let result = try context.fetch(request)
            logger.set(result.count, forKey: "cd.fetch.count")
            logger.log("CoreData: fetch \(entityName) ok")
            return result
        } catch {
            logger.record(error, userInfo: [
                "phase": "fetch",
                "entity": entityName,
                "predicate": String(describing: predicate),
                "sort": String(describing: sortDescriptors)
            ])
            throw CoreDataError.readError(error)
        }
    }

    func update<Entity, Value>(
        _ entity: Entity,
        by keyPath: ReferenceWritableKeyPath<Entity, Value>,
        to value: Value
    ) throws where Entity: NSManagedObject {
        let entityName = String(describing: Entity.self)
        entity[keyPath: keyPath] = value
        do {
            try saveContext()
            logger.log("CoreData: update \(entityName) keyPath=\(keyPath)")
        } catch {
            logger.record(error, userInfo: [
                "phase": "update",
                "entity": entityName,
                "keyPath": String(describing: keyPath)
            ])
            throw CoreDataError.saveError(error)
        }
    }

    func delete<Entity>(
        _ entity: Entity
    ) throws where Entity: NSManagedObject {
        context.delete(entity)
        do {
            try saveContext()
            logger.log("CoreData: delete \(entityName) ok")
        } catch {
            logger.record(error, userInfo: [
                "phase": "delete",
                "entity": entityName
            ])
            throw CoreDataError.deleteError(error)
        }
    }

    func deleteAll<Entity>(_ type: Entity.Type) throws where Entity: NSManagedObject {
        let entityName = String(describing: Entity.self)
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Entity.self))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try persistentContainer.viewContext.execute(deleteRequest) as? NSBatchDeleteResult
            let deletedIDs = result?.result as? [NSManagedObjectID] ?? []
            
            if !deletedIDs.isEmpty {
                let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: deletedIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes,
                                                    into: [persistentContainer.viewContext])
                logger.set(deletedIDs.count, forKey: "cd.batchDelete.count")
                logger.log("CoreData: batch delete \(entityName) ok")
            }
        } catch {
            logger.record(error, userInfo: [
                "phase": "batchDelete",
                "entity": entityName
            ])
            throw CoreDataError.deleteError(error)
        }
    }
}

