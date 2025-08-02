//
//  ScheduleCreateView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import SwiftUI

struct RepeatRule {
    static let tags: [Tag] = Frequency.allCases.map { Tag(name: $0.label) }

    var endDate: Date?
    var frequency: String?
    // 반복 주기 enum
    enum Frequency: CaseIterable, Equatable, Hashable {
        case daily, weekly, monthly, yearly

        var label: String {
            switch self {
            case .daily: return "매일"
            case .weekly: return "매주"
            case .monthly: return "매월"
            case .yearly: return "매년"
            }
        }
    }
}

struct ScheduleCreateView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)

    @State private var isAllDay: Bool = false

    @State private var isRepeated: Bool = false
    @State private var hasRepeatedDone: Bool = false
    @State private var repeatRule: RepeatRule? = nil


    @State private var isAlarm: Bool = false
    @State private var alarm: String = "없음"
    @State private var isFocused: Bool = true

    let alarmOptions = ["없음", "10분 전", "30분 전", "1시간 전"]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    FocusableTextField(text: $title, placeholder: "일정을 입력하세요", isFirstResponder: isFocused)
                        .frame(height: 20)
                }
                
                Divider()
                VStack(alignment: .leading) {
                    TextField("위치 또는 영상 통화", text: $detail)
                        .textContentType(.location)
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Toggle("하루 종일", isOn: $isAllDay)
                    
                    VStack(alignment: .leading) {
                        Text("시작")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                    
                    VStack(alignment: .leading) {
                        Text("종료")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Toggle("반복", isOn: $isRepeated)
                    
                    if isRepeated {
                        HStack(spacing: 12) {
                            FlexibleView(
                                data: RepeatRule.tags,
                                spacing: 8,
                                alignment: .leading
                            ) { tag in
                                TagView(tag: tag, isSelected: repeatRule?.frequency == tag.name)
                                    .onTapGesture {
                                        repeatRule = RepeatRule(endDate: nil, frequency: tag.name)
                                    }
                                    .onDisappear{
                                        repeatRule = nil
                                        hasRepeatedDone = false
                                    }
                            }
                        }
                    }

                    if let repeatRule {
                        Toggle("반복 종료", isOn: $hasRepeatedDone)
                        if hasRepeatedDone {
                            VStack(alignment: .leading) {
                                Text("종료일")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .labelsHidden()
                            }
                        }
                    }

                }
                Divider()
                VStack(alignment: .leading) {
                    Toggle("알람", isOn: $isAlarm)
                    
                }
                
                Spacer()
                Button("저장하기") {
                    saveSchedule()
                }
                .disabled(title.isEmpty)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .init(horizontal: .center, vertical: .center))
                .background(.blue)
                .cornerRadius(CornerRadius.medium)
                .opacity(title.isEmpty ? 0.5 : 1.0)
            }
            .padding()
            .tapToDismissKeyboard()
            .navigationTitle("새 일정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    isFocused = true
                }
            }
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
        newSchedule.repeatRule = repeatRule?.frequency
        newSchedule.alarm = alarm
        newSchedule.scheduleType = "custom"
        newSchedule.createdAt = Date()
        newSchedule.updatedAt = Date()

        print(newSchedule)
        try? CoreDataService.shared.saveContext()
        dismiss()
    }
}
#Preview {
    ScheduleCreateView()
}








