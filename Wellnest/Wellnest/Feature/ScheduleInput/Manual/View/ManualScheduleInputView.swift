//
//  ScheduleCreateView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import SwiftUI

struct ManualScheduleInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: TabBarItem
    @Binding var selectedCreationType: ScheduleCreationType?

    @State private var currentFocus: InputField? = .title

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    inputSection
                    Divider()
                    locationSection
                    Divider()
                    periodSection
                        .padding(.bottom, 5)
                    Divider()
                    repeatSection
                        .padding(.bottom, 5)
                    Divider()
                    alarmSection
                    Spacer()
                }
                .padding()
            }
            .onDisappear {
                UIApplication.hideKeyboard()
            }
            .safeAreaInset(edge: .bottom) {
                saveButton
                    .padding()
                    .background(.white)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationTitle("새 일정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        selectedCreationType = nil
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            }

        }
    }

    // MARK: - View Components

    // MARK: - inputSection

    // 일정 제목
    @State private var title: String = ""

    // 초기에 첫번째 텍스트 필드에 focus.
    @State private var isTextFieldFocused: Bool = true

    enum InputField: Hashable {
        case title
        case detail
    }

    private var inputSection: some View {
        VStack(alignment: .leading) {
            HStack {
                FocusableTextField(
                    text: $title,
                    placeholder: "일정을 입력하세요",
                    isFirstResponder: currentFocus == .title,
                    returnKeyType: .next,
                    keyboardType: .default,
                    onReturn: {
                        currentFocus = .detail
                    },
                    onEditing: {
                        if currentFocus != .title {
                            currentFocus = .title
                        }
                    }
                )
            }
        }
    }

    // MARK: - locationSection

    // 위치
    @State private var location: String = ""

    @State private var showLocationPicker: Bool = false

    @State private var showLocationSearchIcon: Bool = false

    @State private var showLocationSearchSheet = false

    private var locationSection: some View {
        VStack(alignment: .leading) {
            HStack {
                FocusableTextField(
                    text: $location,
                    placeholder: "장소",
                    isFirstResponder: currentFocus == .detail,
                    returnKeyType: .done,
                    keyboardType: .default,
                    onReturn: {
                        currentFocus = nil
                    },
                    onEditing: {
                        if currentFocus != .detail {
                            currentFocus = .detail
                        }
                    }
                )
                .padding(.bottom, Spacing.inline)
                .padding(.top, Spacing.inline)

                Button {
                    showLocationSearchSheet = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $showLocationSearchSheet) {
            LocationSearchView(selectedLocation: $location, isPresented: $showLocationSearchSheet)
        }
    }

    // MARK: - periodSection

    // 시작 일
    @State private var startDate: Date = Date()

    // 종료 일
    @State private var endDate: Date = Date().addingTimeInterval(3600)

    // 하루 종일 여부
    @State private var isAllDay: Bool = false

    private var periodSection: some View {
        PeriodPickerView(
            startDate: $startDate,
            endDate: $endDate,
            isAllDay: $isAllDay
        )
    }

    // MARK: - repeatSection

    // 반복 여부
    @State private var isRepeated: Bool = false

    // 반복 주기
    @State private var selectedRepeatRule: RepeatRule? = nil

    // 반복 종료일 여부
    @State private var hasRepeatEndDate: Bool = false

    // 반복 종료 일 (default value: 오늘로부터 7일 뒤의 날짜)
    @State private var repeatEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    @State private var isRepeatEndDateOpen: Bool = false

    private var repeatSection: some View {
        TagToggleSection(
            title: "반복",
            tags: RepeatRule.tags,
            isOn: $isRepeated,
            selectedTag: $selectedRepeatRule,
            showDetail: selectedRepeatRule != nil,
            detailContent: {
                AnyView(
                    VStack(alignment: .leading) {
                        Toggle("반복 종료", isOn: $hasRepeatEndDate)
                        if hasRepeatEndDate {
                            HStack {
                                DatePickerView(text: "종료일", date: $repeatEndDate, isAllDay: $hasRepeatEndDate, isPresented: $isRepeatEndDateOpen)
                                    .padding(.top, 5)

                            }
                        }
                    }
                )
            },
            onTagTap: { _ in
                currentFocus = nil 
            }

        )
    }

    // MARK: - alarmSection

    // 알람 여부
    @State private var isAlarm: Bool = false

    // 알람 주기
    @State private var alarmRule: AlarmRule? = nil

    private var alarmSection: some View {
        TagToggleSection(
            title: "알람",
            tags: AlarmRule.tags,
            isOn: $isAlarm,
            selectedTag: $alarmRule,
            showDetail: false,
            detailContent: nil
        )
    }

    // 일정 상세 정보 - 아직 미정
    @State private var detail: String = ""

    private var saveButton: some View {
        FilledButton(title: "저장하기") {
            saveSchedule()
            selectedTab = .plan
            selectedCreationType = nil
            dismiss()
        }
        .disabled(title.isEmpty)
        .opacity(title.isEmpty ? 0.5 : 1.0)
    }

}

extension ManualScheduleInputView {

    private func saveSchedule() {
        let newSchedule = ScheduleEntity(context: CoreDataService.shared.context)
        newSchedule.id = UUID()
        newSchedule.title = title
        newSchedule.location = location
        newSchedule.detail = detail
        newSchedule.startDate = startDate
        newSchedule.endDate = endDate
        newSchedule.isAllDay = isAllDay as NSNumber
        newSchedule.isCompleted = false
        newSchedule.repeatRule = selectedRepeatRule?.name
        newSchedule.hasRepeatEndDate = hasRepeatEndDate
        newSchedule.repeatEndDate = repeatEndDate
        newSchedule.alarm = alarmRule?.name
        newSchedule.scheduleType = "custom"
        newSchedule.createdAt = Date()
        newSchedule.updatedAt = Date()

        print(newSchedule)
        try? CoreDataService.shared.saveContext()
    }
}

