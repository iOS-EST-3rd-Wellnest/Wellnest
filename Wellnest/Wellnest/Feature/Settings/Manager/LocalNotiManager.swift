//
//  LocalNotiManager.swift
//  Wellnest
//
//  Created by 전광호 on 8/7/25.
//

import Foundation
import UserNotifications

final class LocalNotiManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotiManager()
    
    /// 알림 설정 권한 확인
    func requestNotificationAuthorization() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("알람 설정 에러: \(error)")
            }
            
            if granted {
                print("알람 설정 허용")
            } else {
                print("알람 설정 거부")
            }
        }
    }
    
    /// 알림 형태 구성
    func scheduleLocalNotification(for schedule: ScheduleEntity) {
        guard let title = schedule.title,
              let startDate = schedule.startDate,
              let alarmName = schedule.alarm,
        let alarmRule = AlarmRule.tags.first(where: { $0.name == alarmName }) else {
        print("알림 등록 실패: 데이터 확인 필요.")
            return
        }
        
        let triggerDate = startDate.addingTimeInterval(alarmRule.timeOffset)
        guard triggerDate > Date() else {
            print("이미 지난 시간입니다.")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Wellnest"
        content.body = alarmBody(title: title, startDate: startDate)
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            ),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: schedule.id?.uuidString ?? UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("\(error.localizedDescription) 알람 등록 실패")
            } else {
                print("\(title) 알람 등록 성공")
            }
        }
    }
    
    func alarmBody(title: String, startDate: Date) -> String {
        let cal = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ko_KR")
        timeFormatter.timeZone = .current
        timeFormatter.dateFormat = "HH:mm"
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "M월 d일 HH:mm"
        
        let when: String
        
        if cal.isDateInToday(startDate) {
            when = "오늘 \(timeFormatter.string(from: startDate))"
        } else if cal.isDateInTomorrow(startDate) {
            when = "내일 \(timeFormatter.string(from: startDate))"
        } else {
            when = dateFormatter.string(from: startDate)
        }
        
        return "\(title) 일정이 \(when)에 시작됩니다."
    }
    
    func localNotiDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
