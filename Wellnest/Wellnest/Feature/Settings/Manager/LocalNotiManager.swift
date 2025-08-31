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
    
    // MARK: - 권한 요청
    /// 사용자에게 로컬 알림 권한을 요청합니다.
    /// - Parameter completion: 권한 부여 여부(`true`/`false`) 콜백. 메인 스레드에서 호출됩니다.
    /// - Note: 시스템 알림창이 표시됩니다. 앱 최초 1회만 의미가 있으며,
    ///         이후 상태는 설정 앱에서 변경할 수 있습니다.
    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error { print("알람 설정 에러: \(error)") }
                DispatchQueue.main.async { completion(granted) }
                
                if granted {
                    print("알람 허용")
                } else {
                    print("알람 거부")
                }
            }
        }
    
    /// 주어진 `ScheduleEntity`를 기반으로 **단발성 로컬 알림**을 예약합니다.
    /// - Parameter schedule: 알림에 사용할 일정 엔티티.
    /// - Important: `schedule.title`, `schedule.startDate`, `schedule.alarm`가 유효해야 하며,
    ///              `AlarmRule.tags`에서 `alarmName`과 일치하는 규칙을 찾을 수 있어야 합니다.
    /// - Note:
    ///   - 트리거 시각은 `startDate + alarmRule.timeOffset` 입니다.
    ///   - 과거 시간(`triggerDate <= Date()`)이면 예약하지 않습니다.
    ///   - 알림 식별자는 `schedule.id?.uuidString`을 사용하고, 없으면 새 UUID를 생성합니다.
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
    
    /// 알림 본문 메시지를 생성합니다.
    /// - Parameters:
    ///   - title: 일정 제목.
    ///   - startDate: 일정 시작 시각.
    /// - Returns: “오늘/내일/날짜 시간” 규칙을 적용한 사용자 친화적 문자열.
    /// - Note: 한국어 로케일/현재 타임존 포맷을 사용합니다.
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
    
    /// `UNUserNotificationCenter`의 delegate를 이 매니저로 설정합니다.
    /// - Note: 보통 앱 시작 시(AppDelegate/SceneDelegate/Application 루트) 한 번 호출합니다.
    func localNotiDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    /// 앱이 **포그라운드** 상태일 때 도착한 알림의 표시 방식을 결정합니다.
    /// - Parameters:
    ///   - center: 알림 센터.
    ///   - notification: 수신된 알림 객체.
    ///   - completionHandler: 표시 옵션을 전달할 핸들러.
    /// - Note: 여기서는 **배너 + 사운드**로 표시합니다. 필요 시 `.list`, `.badge` 등을 추가하세요.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
