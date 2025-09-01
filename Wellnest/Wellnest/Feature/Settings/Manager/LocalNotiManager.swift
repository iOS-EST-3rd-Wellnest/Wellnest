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

    private let logger: CrashLogger
    init(logger: CrashLogger = CrashlyticsLogger()) {
        self.logger = logger
        super.init()
    }

    // MARK: - 권한 요청
    /// 사용자에게 로컬 알림 권한을 요청합니다.
    /// - Parameter completion: 권한 부여 여부(`true`/`false`) 콜백. 메인 스레드에서 호출됩니다.
    /// - Note: 시스템 알림창이 표시됩니다. 앱 최초 1회만 의미가 있으며,
    ///         이후 상태는 설정 앱에서 변경할 수 있습니다.
    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        logger.log("Noti.requestAuthorization start")
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                self.logger.record(error, userInfo: ["phase": "auth"])
            }
            DispatchQueue.main.async { completion(granted) }
            self.logger.set(granted, forKey: "noti.auth.granted")
            self.logger.log(granted ? "Noti.auth granted" : "Noti.auth denied")
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
            logger.record(NSError(domain: "LocalNoti", code: 9801,
                                  userInfo: [NSLocalizedDescriptionKey: "필수 필드 누락(title/startDate/alarmRule)"]),
                          userInfo: ["phase": "schedule"])
            return
        }
        
        let triggerDate = startDate.addingTimeInterval(alarmRule.timeOffset)
        guard triggerDate > Date() else {
            logger.record(NSError(domain: "LocalNoti", code: 9802,
                               userInfo: [NSLocalizedDescriptionKey: "과거 트리거 시각"] ),
                          userInfo: ["phase": "schedule", "offset": Int(alarmRule.timeOffset)])
            return
        }

        logger.set(title.count, forKey: "noti.title.len")
        logger.set(shortHash(title), forKey: "noti.title.hash")
        logger.set(alarmName, forKey: "noti.alarm.name")
        logger.set(Int(alarmRule.timeOffset), forKey: "noti.alarm.offset")
        logger.set(Int(triggerDate.timeIntervalSinceNow), forKey: "noti.ttl.sec")
        logger.log("Noti.schedule start")

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

        let identifier = schedule.id?.uuidString ?? UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                self.logger.record(error, userInfo: [
                    "phase": "addRequest",
                    "id": identifier
                ])
            } else {
                self.logger.log("Noti.schedule success id=\(identifier)")
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
        logger.log("Noti.body composed (today/tomorrow/other)")
        return "\(title) 일정이 \(when)에 시작됩니다."
    }
    
    /// `UNUserNotificationCenter`의 delegate를 이 매니저로 설정합니다.
    /// - Note: 보통 앱 시작 시(AppDelegate/SceneDelegate/Application 루트) 한 번 호출합니다.
    func localNotiDelegate() {
        UNUserNotificationCenter.current().delegate = self
        logger.log("Noti.delegate set")
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
        logger.log("Noti.willPresent id=\(notification.request.identifier)")
        completionHandler([.banner, .sound])
    }

    private func shortHash(_ text: String) -> String {
           let h = text.utf8.reduce(UInt64(1469598103934665603)) { ($0 ^ UInt64($1)) &* 1099511628211 }
           return String(format: "%016llx", h)
       }
}
