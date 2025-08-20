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

    private let morningCheckInId = "wellnest.morning-checkin.9am"

    /// 알림 설정 권한 확인
    func requestNotificationAuthorization() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("알람 설정 에러: \(error)")
            }
            
            if granted {
                print("알람 설정 허용")
                LocalNotiManager.shared.ensureMorningCheckInScheduled()
            } else {
                LocalNotiManager.shared.cancelMorningCheckIn()
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

extension LocalNotiManager {

    func ensureMorningCheckInScheduled() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                // 이미 허용됨 → 스케줄 보장
                self.scheduleMorningCheckInAt9AM()

            case .notDetermined:
                // 아직 미정 → 권한 요청 후 스케줄
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    if granted { self.scheduleMorningCheckInAt9AM() }
                }

            case .denied:
                // 거부 상태 → 스케줄 안 함 (원하면 설정으로 보내는 처리 추가 가능)
                print("알림 권한 거부됨: 설정에서 허용 필요")

            @unknown default:
                break
            }
        }
    }

    /// 매일 오전 9시 “오늘 컨디션은 어떤가요?” 알림 등록 (중복 방지 포함)
    func scheduleMorningCheckInAt9AM() {
        let center = UNUserNotificationCenter.current()

        // 중복 방지: 동일 ID의 기존 예약 제거
        center.removePendingNotificationRequests(withIdentifiers: [morningCheckInId])

        let content = UNMutableNotificationContent()
        content.title = "오늘 컨디션은 어떤가요?"
        content.body  = "아침 체크인으로 하루를 가볍게 시작해요."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = 9
        comps.minute = 0
        // 기기 로컬 타임존에 맞춰 동작 (Asia/Seoul이면 9시에 뜸)

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: morningCheckInId, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("아침 체크인 알림 등록 실패: \(error.localizedDescription)")
            } else {
                print("아침 9시 체크인 알림 등록 완료")
            }
        }
    }

    /// 아침 체크인 알림 해제
    func cancelMorningCheckIn() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [morningCheckInId])
    }
}
