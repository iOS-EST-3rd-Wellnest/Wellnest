//
//  ScheduleEntity+CoreDataProperties.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import Foundation
import CoreData

extension ScheduleEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ScheduleEntity> {
        return NSFetchRequest<ScheduleEntity>(entityName: "ScheduleEntity")
    }

    /// 고유 식별자
    @NSManaged public var id: Int64

    /// 일정 제목 (예: "운동하기", "회의 참석")
    @NSManaged public var title: String

    /// 일정 상세 설명 (옵션)
    @NSManaged public var detail: String?

    /// 일정 시작 시간
    @NSManaged public var startDate: Date

    /// 일정 종료 시간 (옵션)
    @NSManaged public var endDate: Date?

    /// 일정 유형 (예: "daily", "weekly", "monthly")
    @NSManaged public var scheduleType: String

    /// 하루 종일 일정인지 여부
    @NSManaged public var isAllDay: Bool

    /// 일정 완료 여부
    @NSManaged public var isCompleted: Bool

    /// 반복 규칙 (예: "none", "daily", "weekly", "monthly", "custom")
    @NSManaged public var repeatRule: String?

    /// 사용자 정의 카테고리 (예: "운동", "식사", "업무")
    @NSManaged public var category: String?

    /// 생성 일자
    @NSManaged public var createdAt: Date

    /// 마지막 수정 일자
    @NSManaged public var updatedAt: Date

    /// 알림 설정 정보 (예: "10분 전", "하루 전", "정시에")
    @NSManaged public var alarm: String?

    /// 이 일정이 속한 하루 요약(DailySummary) 엔티티와의 관계
    @NSManaged public var parentSummary: DailySummaryEntity?
}
