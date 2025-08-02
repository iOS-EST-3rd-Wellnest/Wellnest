//
//  TodayScheduleListView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import SwiftUI
import CoreData

struct TodayScheduleListView: View {
    @Environment(\.managedObjectContext) private var context

    @State private var schedules: [ScheduleEntity] = []
    @State private var showCreateSheet = false

    var body: some View {
        NavigationView {
            List {
                if schedules.isEmpty {
                    Text("오늘 할 일이 없습니다 🎉")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(schedules, id: \.self) { schedule in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(schedule.title)
                                    .font(.headline)
                                if let detail = schedule.detail, !detail.isEmpty {
                                    Text(detail)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                if !schedule.isAllDay {
                                    Text(schedule.startDate.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }

                            Spacer()

                            Image(systemName: schedule.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(schedule.isCompleted ? .green : .gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("오늘의 일정")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        loadTodaySchedules()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }

            }
            .onAppear(perform: loadTodaySchedules)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateSheet = true
                    }) {
                           Image(systemName: "plus")
                       }
                   }
                }
                .sheet(isPresented: $showCreateSheet) {
                   ScheduleCreateView()
                       .environment(\.managedObjectContext, context) // 전달 필수
                }
        }
    }

    private func loadTodaySchedules() {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")

        print("🕐 now (KST):", formatter.string(from: start))
        print("🕐 startOfToday (KST):", formatter.string(from: end))

        let predicate = NSPredicate(
            format: "startDate < %@ AND endDate > %@",
            end as NSDate,
            start as NSDate
        )


        do {
            schedules = try CoreDataService.shared.fetch(
                ScheduleEntity.self,
                predicate: predicate,
                sortDescriptors: [NSSortDescriptor(keyPath: \ScheduleEntity.id, ascending: true)]
            )

            print(schedules)

        } catch {
            print(error)
        }
    }
}

#Preview {
    TodayScheduleListView()
}
