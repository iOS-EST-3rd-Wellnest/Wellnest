//
//  UserEntity+CoreDataProperties.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import Foundation
import CoreData

extension UserEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var id: Int64
    @NSManaged public var ageRange: String
    @NSManaged public var gender: String
    @NSManaged public var height: NSNumber?
    @NSManaged public var weight: NSNumber?
    @NSManaged public var goal: String?
    @NSManaged public var activityPreferrences: String?
    @NSManaged public var preferredTimeSlot: String?
    @NSManaged public var healthConditions: String?
    @NSManaged public var createdAt: Date
}
