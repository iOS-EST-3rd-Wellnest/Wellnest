//
//  LocalNotifying.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/16/25.
//

import Foundation

protocol LocalNotifying {
    func scheduleLocalNotification(for schedule: ScheduleEntity)
}

// 기존 매니저를 바로 채택
extension LocalNotiManager: LocalNotifying {}

