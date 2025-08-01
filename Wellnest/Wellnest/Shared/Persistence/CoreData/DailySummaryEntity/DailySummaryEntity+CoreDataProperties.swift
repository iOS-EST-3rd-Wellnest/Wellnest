//
//  DailySummaryEntity+CoreDataProperties.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import Foundation
import CoreData

extension DailySummaryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailySummaryEntity> {
        return NSFetchRequest<DailySummaryEntity>(entityName: "DailySummaryEntity")
    }

    /// 고유 식별자
    @NSManaged public var id: UUID

    /// 해당 날짜
    @NSManaged public var date: Date

    /// 오늘 일정의 달성률 (0~100 정수)
    @NSManaged public var completeRate: Int64

    /// 오늘의 목표 (예: "10000보 걷기")
    @NSManaged public var goal: String?

    /// 오늘의 한마디 또는 명언
    @NSManaged public var quoteOfDay: String?

    /// 요약된 날씨 정보 (예: "맑음 27도")
    @NSManaged public var weatherSummary: String?

    /// 추천 식단 (예: "현미밥 + 연어구이")
    @NSManaged public var mealRecommendation: String?

    /// 추천 영상 URL 또는 제목
    @NSManaged public var videoRecommendation: String?

    /// 추천 글 요약 또는 제목
    @NSManaged public var articleRecommendation: String?

    /// 하루에 해당하는 일정 목록 (ScheduleEntity와의 1:N 관계)
    @NSManaged public var schedules: Set<ScheduleEntity>?
}
