//
//  CoreDataStore.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/16/25.
//

import CoreData

public actor CoreDataStore {

    private let container: NSPersistentContainer
    private let ctx: NSManagedObjectContext

    public init(container: NSPersistentContainer = CoreDataStack.shared.container) {
        self.container = container
        self.ctx = container.newBackgroundContext()
        self.ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Create
    @discardableResult
    public func create<Entity: NSManagedObject>(
        _ type: Entity.Type,
        configure: @escaping (Entity) -> Void
    ) async throws -> NSManagedObjectID {
        let context = self.ctx
        return try await context.perform {
            let name = String(describing: Entity.self)
            guard let obj = NSEntityDescription.insertNewObject(forEntityName: name, into: context) as? Entity else {
                throw CoreDataError.castFailed(name)
            }
            configure(obj)
            try context.save()
            return obj.objectID
        }
    }

    // MARK: - Fetch (IDs)
    public func fetchIDs<Entity: NSManagedObject>(
        _ type: Entity.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fetchLimit: Int = 0
    ) async throws -> [NSManagedObjectID] {
        let context = self.ctx
        return try await context.perform {
            let req = NSFetchRequest<NSManagedObjectID>(entityName: String(describing: Entity.self))
            req.predicate = predicate
            req.sortDescriptors = sortDescriptors
            req.resultType = .managedObjectIDResultType
            if fetchLimit > 0 { req.fetchLimit = fetchLimit }
            do {
                return try context.fetch(req)
            } catch {
                throw CoreDataError.readError(error)
            }
        }
    }

    // MARK: - Fetch (DTO 변환)
    public func fetchDTOs<Entity: NSManagedObject, DTO>(
        _ type: Entity.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        map: @escaping (Entity) -> DTO
    ) async throws -> [DTO] {
        let context = self.ctx
        return try await context.perform {
            let req = NSFetchRequest<Entity>(entityName: String(describing: Entity.self))
            req.predicate = predicate
            req.sortDescriptors = sortDescriptors
            do {
                let objs = try context.fetch(req)
                return objs.map(map)
            } catch {
                throw CoreDataError.readError(error)
            }
        }
    }

    // MARK: - Update (by ID)
    public func update<Entity: NSManagedObject>(
        id: NSManagedObjectID,
        apply changes: @escaping (Entity) -> Void
    ) async throws {
        let context = self.ctx
        try await context.perform {
            guard let obj = try? context.existingObject(with: id) as? Entity else { return }
            changes(obj)
            do { try context.save() } catch { throw CoreDataError.saveError(error) }
        }
    }

    // MARK: - Delete (by ID)
    public func delete(id: NSManagedObjectID) async throws {
        try await ctx.perform {
            let context = self.ctx
            if let obj = try? context.existingObject(with: id) {
                context.delete(obj)
                do { try context.save() } catch { throw CoreDataError.deleteError(error) }
            }
        }
    }

    // MARK: - Delete All
    public func deleteAll<Entity: NSManagedObject>(_ type: Entity.Type) async throws {
        let context = self.ctx
        let container = self.container
        try await context.perform {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Entity.self))
            let del = NSBatchDeleteRequest(fetchRequest: fetch)
            del.resultType = .resultTypeObjectIDs
            do {
                let result = try context.execute(del) as? NSBatchDeleteResult
                if let ids = result?.result as? [NSManagedObjectID] {
                    // UI 컨텍스트에 변경 사항 머지
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                        into: [container.viewContext]
                    )
                }
                try context.save()
            } catch {
                throw CoreDataError.deleteError(error)
            }
        }
    }

    
}
