//
//  ScheduleCreateView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import SwiftUI

struct ScheduleCreateView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var isAllDay: Bool = false
    @State private var repeatRule: String = "none"
    @State private var category: String = "기타"
    @State private var alarm: String = "없음"

    let repeatOptions = ["none", "daily", "weekly", "monthly"]
        let categoryOptions = ["운동", "식사", "업무", "기타"]
        let alarmOptions = ["없음", "10분 전", "30분 전", "1시간 전"]

        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("일정 정보")) {
                        TextField("제목", text: $title)
                        TextField("상세 설명", text: $detail)
                    }

                    Section(header: Text("시간")) {
                        Toggle("하루 종일", isOn: $isAllDay)
                        DatePicker("시작 시간", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                        DatePicker("종료 시간", selection: $endDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                    }

                    Section(header: Text("옵션")) {
                        Picker("반복", selection: $repeatRule) {
                            ForEach(repeatOptions, id: \.self) { Text($0) }
                        }

                        Picker("카테고리", selection: $category) {
                            ForEach(categoryOptions, id: \.self) { Text($0) }
                        }

                        Picker("알림", selection: $alarm) {
                            ForEach(alarmOptions, id: \.self) { Text($0) }
                        }
                    }

                    Button("저장하기") {
                        saveSchedule()
                    }
                }
                .navigationTitle("새 일정")
                .navigationBarTitleDisplayMode(.inline)
            }
        }

}

extension ScheduleCreateView {

    private func saveSchedule() {
          let newSchedule = ScheduleEntity(context: context)
          newSchedule.id = UUID()
          newSchedule.title = title
          newSchedule.detail = detail
          newSchedule.startDate = startDate
          newSchedule.endDate = endDate
          newSchedule.isAllDay = isAllDay
          newSchedule.isCompleted = false
          newSchedule.repeatRule = repeatRule
          newSchedule.category = category
          newSchedule.alarm = alarm
          newSchedule.scheduleType = "custom"
          newSchedule.createdAt = Date()
          newSchedule.updatedAt = Date()

          try? CoreDataService.shared.saveContext()
          dismiss()
      }
}
#Preview {
    ScheduleCreateView()
}
