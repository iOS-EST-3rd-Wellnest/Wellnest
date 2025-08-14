//
//  SaveAISchedule.swift
//  Wellnest
//
//  Created by junil on 8/7/25.
//

import Foundation

extension AIScheduleResultView {
    func saveAISchedules() {
        guard let plan = viewModel.healthPlan else { return }

        print("AI 스케줄 저장 시작 - 스케줄 개수: \(plan.schedules.count)")

        for (index, scheduleItem) in plan.schedules.enumerated() {
            let newSchedule = ScheduleEntity(context: CoreDataService.shared.context)
            newSchedule.id = UUID()
            newSchedule.title = scheduleItem.activity
            newSchedule.location = ""
            newSchedule.detail = scheduleItem.notes ?? ""

            // AIScheduleDateTimeHelper를 사용하여 날짜/시간 설정
            let dates = AIScheduleDateTimeHelper.parseDatesForCoreData(
                scheduleItem: scheduleItem,
                planType: plan.planType
            )
            newSchedule.startDate = dates.startDate
            newSchedule.endDate = dates.endDate

            newSchedule.isAllDay = false
            newSchedule.isCompleted = false
            newSchedule.repeatRule = plan.planType == "routine" ? "weekly" : nil
            newSchedule.hasRepeatEndDate = false
            newSchedule.repeatEndDate = nil
            newSchedule.alarm = nil
            newSchedule.scheduleType = "ai_generated"
            newSchedule.createdAt = Date()
            newSchedule.updatedAt = Date()

            print("📝 AI 스케줄 \(index + 1) 생성: \(newSchedule.title ?? "제목없음") - 시작: \(newSchedule.startDate ?? Date()) - 종료: \(newSchedule.endDate ?? Date())")
        }

        do {
            try CoreDataService.shared.saveContext()
            print("Core Data 저장 완료")
        } catch {
            print("저장 실패: \(error)")
        }
    }
}
