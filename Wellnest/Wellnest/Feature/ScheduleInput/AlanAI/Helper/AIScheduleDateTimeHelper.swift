//
//  AIScheduleDateTimeHelper.swift
//  Wellnest
//
//  Created by junil on 8/9/25.
//

import Foundation

struct AIScheduleDateTimeHelper {

    static func parseDatesForCoreData(scheduleItem: AIScheduleItem, planType: String) -> (startDate: Date, endDate: Date) {
        let startDate: Date
        let endDate: Date
        
        if let dateString = scheduleItem.date {
            startDate = parseDate(from: dateString, time: scheduleItem.time)
            endDate = parseEndDate(from: dateString, time: scheduleItem.time)
        } else if let dayString = scheduleItem.day {
            startDate = getNextDate(for: dayString, time: scheduleItem.time)
            endDate = parseEndDate(from: nil, time: scheduleItem.time, baseDate: startDate)
        } else {
            let now = Date()
            startDate = now
            endDate = now.addingTimeInterval(3600)
        }
        
        return (startDate, endDate)
    }

    private static func parseDate(from dateString: String?, time: String) -> Date {
        let calendar = Calendar.current
        let now = Date()

        let timeComponents = parseTime(from: time)
        
        if let dateString = dateString {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko_KR")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            
            if let date = dateFormatter.date(from: dateString) {
                return calendar.date(bySettingHour: timeComponents.hour,
                                   minute: timeComponents.minute,
                                   second: 0,
                                   of: date) ?? now
            }
        }

        return calendar.date(bySettingHour: timeComponents.hour,
                           minute: timeComponents.minute,
                           second: 0,
                           of: now) ?? now
    }

    private static func parseEndDate(from dateString: String?, time: String, baseDate: Date? = nil) -> Date {
        let startDate = baseDate ?? parseDate(from: dateString, time: time)

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

        return startDate.addingTimeInterval(3600)
    }

    private static func parseTime(from timeString: String) -> (hour: Int, minute: Int) {
        let cleanTime = timeString.components(separatedBy: "-")[0].trimmingCharacters(in: .whitespaces)
        let components = cleanTime.components(separatedBy: ":")
        
        if components.count >= 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            return (hour: hour, minute: minute)
        }
        
        return (hour: 9, minute: 0)
    }

    private static func getNextDate(for dayString: String, time: String) -> Date {
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
            daysToAdd += 7
        }
        
        let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
        
        let timeComponents = parseTime(from: time)
        return calendar.date(bySettingHour: timeComponents.hour,
                           minute: timeComponents.minute,
                           second: 0,
                           of: targetDate) ?? today
    }
}
