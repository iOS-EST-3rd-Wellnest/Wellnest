//
//  ScheduleItem.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/3/25.
//

import SwiftUI

struct ScheduleItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let createdAt: Date
    let updatedAt: Date
    let backgroundColor: String
    let isAllDay: Bool
    let repeatRule: String?
    let hasRepeatEndDate: Bool
    let repeatEndDate: Date?
    let isCompleted: Bool
}

enum DataLoader {
    static func loadScheduleItems() -> [ScheduleItem] {
        guard let url = Bundle.main.url(forResource: "schedule_dummy_data", withExtension: "json") else {
            print("❌ JSON 파일을 찾을 수 없습니다.")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()

            // ISO8601 비슷하지만 타임존 없는 형태용 DateFormatter
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current

            decoder.dateDecodingStrategy = .formatted(formatter)

            return try decoder.decode([ScheduleItem].self, from: data)
        } catch {
            print("❌ JSON 디코딩 실패:", error)
            return []
        }
    }
}
