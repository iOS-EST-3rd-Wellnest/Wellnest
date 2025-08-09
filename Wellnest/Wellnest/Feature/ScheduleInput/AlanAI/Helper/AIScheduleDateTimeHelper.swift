//
//  AIScheduleDateTimeHelper.swift
//  Wellnest
//
//  Created by junil on 8/9/25.
//

import Foundation

struct AIScheduleDateTimeHelper {
    
    // MARK: - Public Methods
    
    /// AI 스케줄 아이템을 Core Data 엔티티에 저장할 날짜/시간으로 파싱
    static func parseDatesForCoreData(scheduleItem: AIScheduleItem, planType: String) -> (startDate: Date, endDate: Date) {
        let startDate: Date
        let endDate: Date
        
        if let dateString = scheduleItem.date {
            // 특정 날짜가 있는 경우
            startDate = parseDate(from: dateString, time: scheduleItem.time)
            endDate = parseEndDate(from: dateString, time: scheduleItem.time)
        } else if let dayString = scheduleItem.day {
            // 요일 기반인 경우 (루틴)
            startDate = getNextDate(for: dayString, time: scheduleItem.time)
            endDate = parseEndDate(from: nil, time: scheduleItem.time, baseDate: startDate)
        } else {
            // 기본값
            let now = Date()
            startDate = now
            endDate = now.addingTimeInterval(3600)
        }
        
        return (startDate, endDate)
    }
    
    // MARK: - Private Methods
    
    /// 날짜 문자열과 시간 문자열을 Date 객체로 파싱
    private static func parseDate(from dateString: String?, time: String) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 시간 파싱
        let timeComponents = parseTime(from: time)
        
        if let dateString = dateString {
            // 특정 날짜가 있는 경우
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko_KR")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current // 현지 시간대 사용
            
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
    
    /// 종료 날짜/시간 파싱
    private static func parseEndDate(from dateString: String?, time: String, baseDate: Date? = nil) -> Date {
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
    
    /// 시간 문자열을 시간, 분으로 파싱
    private static func parseTime(from timeString: String) -> (hour: Int, minute: Int) {
        let cleanTime = timeString.components(separatedBy: "-")[0].trimmingCharacters(in: .whitespaces)
        let components = cleanTime.components(separatedBy: ":")
        
        if components.count >= 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            return (hour: hour, minute: minute)
        }
        
        return (hour: 9, minute: 0) // 기본값
    }
    
    /// 요일 문자열로부터 다음 해당 요일의 날짜를 가져오기
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
            daysToAdd += 7 // 다음 주
        }
        
        let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
        
        // 시간 설정을 위해 parseDate 사용
        let timeComponents = parseTime(from: time)
        return calendar.date(bySettingHour: timeComponents.hour,
                           minute: timeComponents.minute,
                           second: 0,
                           of: targetDate) ?? today
    }
}
