//
//  ScheduleCreateView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import SwiftUI


struct ScheduleCreateView: View {
    @EnvironmentObject var viewModel: ScheduleViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var repeatEndDate = Date()

    // 하루 종일 여부
    @State private var isAllDay: Bool = false

    // 반복 여부
    @State private var isRepeated: Bool = false

    // 반복 종료일 여부
    @State private var hasRepeatedDone: Bool = false

    // 반복 주기
    @State private var selectedRepeatRule: RepeatRule? = nil

    // 알람 여부
    @State private var isAlarm: Bool = false

    // 알람 주기
    @State private var alarmRule: AlarmRule? = nil

    // 초기에 첫번째 텍스트 필드에 focus
    @State private var isTextFieldFocused: Bool = true

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        FocusableTextField(text: $title, placeholder: "일정을 입력하세요", isFirstResponder: isTextFieldFocused)
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

                    TagToggleSection(
                        title: "반복",
                        tags: RepeatRule.tags,
                        isOn: $isRepeated,
                        selectedTag: $selectedRepeatRule,
                        showDetail: selectedRepeatRule != nil,
                        detailContent: {
                            AnyView(
                                VStack(alignment: .leading) {
                                    Toggle("반복 종료", isOn: $hasRepeatedDone)

                                    if hasRepeatedDone {
                                        VStack(alignment: .leading) {
                                            Text("종료일")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            DatePicker(
                                                "",
                                                selection: $repeatEndDate,
                                                in: Date()...,
                                                displayedComponents: .date
                                            )
                                            .labelsHidden()
                                        }
                                    }
                                }
                            )
                        }
                    )
                    Divider()
                    TagToggleSection(
                        title: "알람",
                        tags: AlarmRule.tags,
                        isOn: $isAlarm,
                        selectedTag: $alarmRule,
                        showDetail: false,
                        detailContent: nil
                    )

                    Spacer()
                    Button("저장하기") {
                        saveSchedule()
                        viewModel.loadTodaySchedules() // 👈 저장 후 홈 화면 갱신되도록
                        dismiss()
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
                        isTextFieldFocused = true
                    }
                }
            }

        }
    }
}

extension ScheduleCreateView {
    private func saveSchedule() {
        let newSchedule = ScheduleEntity(context: CoreDataService.shared.context)
        newSchedule.id = UUID()
        newSchedule.title = title
        newSchedule.detail = detail
        newSchedule.startDate = startDate
        newSchedule.endDate = endDate
        newSchedule.isAllDay = isAllDay
        newSchedule.isCompleted = false
        newSchedule.repeatRule = selectedRepeatRule?.name
        newSchedule.alarm = alarmRule?.name
        newSchedule.scheduleType = "custom"
        newSchedule.createdAt = Date()
        newSchedule.updatedAt = Date()

        print(newSchedule)
        try? CoreDataService.shared.saveContext()
    }
}
#Preview {
    ScheduleCreateView()
}
