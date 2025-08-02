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

    // 하루 종일 여부
    @State private var isAllDay: Bool = false

    // 반복 여부
    @State private var isRepeated: Bool = false

    // 반복 종료일 여부
    @State private var hasRepeatedDone: Bool = false

    // 반복 주기
    @State private var repeatRule: RepeatRule? = nil

    // 알람 여부
    @State private var isAlarm: Bool = false

    // 알람 주기
    @State private var alarmRule: AlarmRule? = nil

    // 초기에 첫번째 텍스트 필드에 focus
    @State private var isTextFiledFocused: Bool = true

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        FocusableTextField(text: $title, placeholder: "일정을 입력하세요", isFirstResponder: isTextFiledFocused)
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

                        if isAlarm {
                            HStack(spacing: 12) {
                                FlexibleView(
                                    data: AlarmRule.tags,
                                    spacing: 8,
                                    alignment: .leading
                                ) { tag in
                                    TagView(tag: tag, isSelected: alarmRule?.frequency == tag.name)
                                        .onTapGesture {
                                            alarmRule = AlarmRule(frequency: tag.name)
                                        }
                                        .onDisappear{
                                            alarmRule = nil
                                        }
                                }
                            }
                        }

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
                        isTextFiledFocused = true
                    }
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
        newSchedule.alarm = alarmRule?.frequency
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
