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
    // 일정 제목
    @State private var title: String = ""

    @State private var selectedColor: Color = .blue

    enum InputField: Hashable {
        case title
    }

    // MARK: - locationSection

    // 위치
    @State private var location: String = ""

    @State private var showLocationPicker: Bool = false

    @State private var showLocationSearchIcon: Bool = false

    @State private var showLocationSearchSheet = false


    // MARK: - periodSection

    // 시작 일
    @State private var startDate: Date = Date()

    // 종료 일
    @State private var endDate: Date = Date().addingTimeInterval(3600)

    // 하루 종일 여부
    @State private var isAllDay: Bool = false


    // MARK: - repeatSection

    // 반복 여부
    @State private var isRepeated: Bool = false

    // 반복 주기
    @State private var selectedRepeatRule: RepeatRule? = nil

    // 반복 종료일 여부
    @State private var hasRepeatEndDate: Bool = true

    // 반복 종료 일 (default value: 오늘로부터 7일 뒤의 날짜)
    @State private var repeatEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    @State private var isRepeatEndDateOpen: Bool = false


    // MARK: - alarmSection

    // 알람 여부
    @State private var isAlarm: Bool = false

    // 알람 주기
    @State private var alarmRule: AlarmRule? = nil

    // 일정 상세 정보 - 아직 미정
    @State private var detail: String = ""


    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: Spacing.layout) {
                    VStack {
                        HStack {
                            FocusableTextField(
                                text: $title,
                                placeholder: "일정을 입력하세요.",
                                isFirstResponder: currentFocus == .title,
                                returnKeyType: .next,
                                keyboardType: .default,
                                onReturn: {
                                    currentFocus = nil
                                    showLocationSearchSheet = true

                                },
                                onEditing: {
                                    if currentFocus != .title {
                                        currentFocus = .title
                                    }
                                }
                            )
                        }
                        Divider()
                        HStack {
                            Button {
                                currentFocus = nil
                                showLocationSearchSheet = true
                            } label: {
                                HStack {
                                    Text(location.isEmpty ? "장소" : location)
                                        .foregroundStyle(location.isEmpty ? .tertiary : .primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "magnifyingglass")
                                        .frame(width: 20, height: 20)
                                }
                                .contentShape(Rectangle())
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)

                        }
                        .padding(.top, 2)
                        .sheet(isPresented: $showLocationSearchSheet) {
                            LocationSearchView(selectedLocation: $location, isPresented: $showLocationSearchSheet)
                        }
                        Divider()
                    }
                    PeriodPickerView(
                        startDate: $startDate,
                        endDate: $endDate,
                        isAllDay: $isAllDay
                    )
                    .padding(.bottom, 5)
                    TagToggleSection(
                        title: "반복",
                        tags: RepeatRule.tags,
                        isOn: $isRepeated,
                        selectedTag: $selectedRepeatRule,
                        showDetail: selectedRepeatRule != nil,
                        detailContent: {
                            AnyView(
                                EndDateSelectorView(endDate: $repeatEndDate)
                            )
                        },
                        onTagTap: { _ in
                            currentFocus = nil
                        }
                    )
                    .padding(.bottom, 5)
                    .onChange(of: isRepeated) { newValue in
                        UIApplication.hideKeyboard()
                    }
                    TagToggleSection(
                        title: "알람",
                        tags: AlarmRule.tags,
                        isOn: $isAlarm,
                        selectedTag: $alarmRule,
                        showDetail: false,
                        detailContent: nil
                    )
                    .padding(.bottom, 5)
                    .onChange(of: isAlarm) { newValue in
                        UIApplication.hideKeyboard()
                    }
                    HStack {
                        Text("배경색")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        ColorPicker("배경 색상 선택", selection: $selectedColor)
                            .labelsHidden()
                    }
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
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedCreationType = nil
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        FilledButton(title: "저장하기", disabled: title.isEmpty) {
            saveSchedule()
            selectedTab = .plan
            selectedCreationType = nil
            dismiss()
        }
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
        
        if isAlarm {
            LocalNotiManager.shared.scheduleLocalNotification(for: newSchedule)
        }
    }
}

