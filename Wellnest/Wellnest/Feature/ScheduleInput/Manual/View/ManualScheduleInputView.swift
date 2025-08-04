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

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    inputSection
                    Divider()
                    locationSection
                    Divider()
                    periodSection
                    Divider()
                    repeatSection
                    Divider()
                    alarmSection
                    Spacer()
                }
                .padding()
            }
            .onDisappear {
                UIApplication.hideKeyboard()
            }
            .onTapGesture {
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
                ToolbarItem(placement: .destructiveAction) {
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

    @State private var currentFocus: InputField? = .title

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
                        DispatchQueue.main.async {
                            currentFocus = .detail
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
                        DispatchQueue.main.async {
                            currentFocus = nil
                        }
                        UIApplication.hideKeyboard()
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

    @State private var startDate: Date = Date()
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

    // 반복 종료 일
    @State private var repeatEndDate = Date()

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

