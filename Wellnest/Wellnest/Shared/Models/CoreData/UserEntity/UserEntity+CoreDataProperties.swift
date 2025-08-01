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

    /// 고유 식별자
    @NSManaged public var id: Int64

    /// 연령대 (예: "20대", "30대", "40대")
    @NSManaged public var ageRange: String

    /// 성별 (예: "남성", "여성", "기타")
    @NSManaged public var gender: String

    /// 키 (cm 단위, NSNumber 사용 — optional)
    @NSManaged public var height: NSNumber?

    /// 몸무게 (kg 단위, NSNumber 사용 — optional)
    @NSManaged public var weight: NSNumber?

    /// 웰니스 목표 (예: "체중 감량", "근육 증가", "스트레스 완화")
    @NSManaged public var goal: String?

    /// 선호 활동 (쉼표로 구분된 문자열 예: "요가,홈트레이닝,러닝")
    @NSManaged public var activityPreferrences: String?

    /// 선호 시간대 (예: "아침", "저녁", 쉼표로 복수 가능)
    @NSManaged public var preferredTimeSlot: String?

    /// 건강 상태 (예: "정상", "고혈압", "당뇨", 쉼표로 구분된 복수 값 가능)
    @NSManaged public var healthConditions: String?

    /// 프로필 생성 일자
    @NSManaged public var createdAt: Date
}
