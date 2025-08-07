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

        for scheduleItem in plan.schedules {
            let newSchedule = ScheduleEntity(context: CoreDataService.shared.context)
            newSchedule.id = UUID()
            newSchedule.title = scheduleItem.activity
            newSchedule.location = ""
            newSchedule.detail = scheduleItem.notes ?? ""

            // AI 스케줄의 날짜와 시간 설정
            if let dateString = scheduleItem.date {
                // 특정 날짜가 있는 경우
                newSchedule.startDate = parseDate(from: dateString, time: scheduleItem.time)
                newSchedule.endDate = parseEndDate(from: dateString, time: scheduleItem.time)
            } else if let dayString = scheduleItem.day {
                // 요일 기반인 경우 (루틴)
                newSchedule.startDate = getNextDate(for: dayString, time: scheduleItem.time)
                newSchedule.endDate = parseEndDate(from: nil, time: scheduleItem.time, baseDate: newSchedule.startDate)
            } else {
                // 기본값
                newSchedule.startDate = Date()
                newSchedule.endDate = Date().addingTimeInterval(3600)
            }

            newSchedule.isAllDay = false
            newSchedule.isCompleted = false
            newSchedule.repeatRule = plan.planType == "routine" ? "weekly" : nil
            newSchedule.hasRepeatEndDate = false
            newSchedule.repeatEndDate = nil
            newSchedule.alarm = nil
            newSchedule.scheduleType = "ai_generated"
            newSchedule.createdAt = Date()
            newSchedule.updatedAt = Date()

            print("AI Generated Schedule: \(newSchedule)")
        }

        try? CoreDataService.shared.saveContext()
    }

    private func parseDate(from dateString: String?, time: String) -> Date {
        let calendar = Calendar.current
        let now = Date()

        // 시간 파싱
        let timeComponents = parseTime(from: time)

        if let dateString = dateString {
            // 특정 날짜가 있는 경우
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko_KR")
            dateFormatter.dateFormat = "yyyy-MM-dd"

            if let date = dateFormatter.date(from: dateString) {
                return calendar.date(bySettingHour: timeComponents.hour,
                                   minute: timeComponents.minute,
                                   second: 0,
                                   of: date) ?? now
            }
        }

        // 기본값: 오늘 날짜에 시간 설정
        return calendar.date(bySettingHour: timeComponents.hour,
                           minute: timeComponents.minute,
                           second: 0,
                           of: now) ?? now
    }

    private func parseEndDate(from dateString: String?, time: String, baseDate: Date? = nil) -> Date {
        let startDate = baseDate ?? parseDate(from: dateString, time: time)

        // 시간 범위 파싱 (예: "09:00 - 10:00")
        if time.contains("-") {
            let timeComponents = time.components(separatedBy: "-")
            if timeComponents.count == 2 {
                let endTimeString = timeComponents[1].trimmingCharacters(in: .whitespaces)
                let endTimeComponents = parseTime(from: endTimeString)

                let calendar = Calendar.current
                return calendar.date(bySettingHour: endTimeComponents.hour,
                                   minute: endTimeComponents.minute,
                                   second: 0,
                                   of: startDate) ?? startDate.addingTimeInterval(3600)
            }
        }

        // 기본값: 1시간 후
        return startDate.addingTimeInterval(3600)
    }

    private func parseTime(from timeString: String) -> (hour: Int, minute: Int) {
        let cleanTime = timeString.components(separatedBy: "-")[0].trimmingCharacters(in: .whitespaces)
        let components = cleanTime.components(separatedBy: ":")

        if components.count >= 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            return (hour: hour, minute: minute)
        }

        return (hour: 9, minute: 0) // 기본값
    }

    private func getNextDate(for dayString: String, time: String) -> Date {
        let calendar = Calendar.current
        let today = Date()

        let weekdayMapping: [String: Int] = [
            "일요일": 1, "월요일": 2, "화요일": 3, "수요일": 4,
            "목요일": 5, "금요일": 6, "토요일": 7
        ]

        guard let targetWeekday = weekdayMapping[dayString] else {
            return parseDate(from: nil, time: time)
        }

        let currentWeekday = calendar.component(.weekday, from: today)
        var daysToAdd = targetWeekday - currentWeekday

        if daysToAdd <= 0 {
            daysToAdd += 7 // 다음 주
        }

        let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
        return parseDate(from: nil, time: time)
    }
}
