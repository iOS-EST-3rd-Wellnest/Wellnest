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

    private init() {}

    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Wellnest")
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("error \(error), \(error.userInfo)")
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
                print("Core Data Saved.")
            } catch {
                let nserror = error as NSError
                print("Failed to save Core Data: \(nserror), \(nserror.userInfo)")
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
            fatalError("Failed to create entity \(entityName)")
        }
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
            return try context.fetch(request)
        } catch {
            throw CoreDataError.readError(error)
        }
    }

    func update<Entity, Value>(
        _ entity: Entity,
        by keyPath: ReferenceWritableKeyPath<Entity, Value>,
        to value: Value
    ) throws where Entity: NSManagedObject {
        entity[keyPath: keyPath] = value
        do {
            try saveContext()
        } catch {
            throw CoreDataError.saveError(error)
        }

    }

    func delete<Entity>(
        _ entity: Entity
    ) throws where Entity: NSManagedObject {
        context.delete(entity)
        do {
            try saveContext()
        } catch {
            throw CoreDataError.deleteError(error)
        }
    }

    func deleteAll<Entity>(_ type: Entity.Type) throws where Entity: NSManagedObject {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Entity.self))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try persistentContainer.viewContext.execute(deleteRequest) as? NSBatchDeleteResult
            // 삭제된 objectID들
            let deletedIDs = result?.result as? [NSManagedObjectID] ?? []
            
            // 삭제 ID가 있다면
            if !deletedIDs.isEmpty {
                // 변경 딕셔너리 구성
                let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: deletedIDs]
                // viewContext에 변경사항 머지
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes,
                                                    into: [persistentContainer.viewContext])
            }
        } catch {
            throw CoreDataError.deleteError(error)
        }
    }
}

