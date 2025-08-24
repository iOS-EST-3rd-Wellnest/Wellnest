//
//  ScheduleCreateView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import SwiftUI
import CoreData

struct ManualScheduleInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: TabBarItem
    @Binding var selectedCreationType: ScheduleCreationType?

    // 뷰모델(서비스) — 관찰 필요 없으므로 let
    private let editor: ManualScheduleInputViewModel = {
        // 필요 시 DI로 주입 가능
        return ScheduleEditorFactory.makeDefault()
    }()

    @State private var lastSavedID: NSManagedObjectID?

    // 일정 제목
    @State private var title: String = ""
    @State private var selectedColorName = "accentButtonColor"
    @State private var previewColor: Color = Color("accentButtonColor")
    @State private var showColorPickerSheet = false

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
    @State private var isAlarmOn: Bool = false

    // 알람 주기
    @State private var alarmRule: AlarmRule? = nil

    // 일정 상세 정보 - 아직 미정
    @State private var detail: String = ""

    @State var isKeyboardVisible: Bool = true

    @State private var didInit = false
    @State private var isSaving = false
    
    @State private var eventIdentifier: String?


    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: Spacing.layout) {
                        VStack {
                            HStack {
                                FocusableTextField(
                                    text: $title,
                                    placeholder: "일정을 입력하세요.",
                                    isFirstResponder: isKeyboardVisible,
                                    returnKeyType: .next,
                                    keyboardType: .default,
                                    onReturn: {
                                        showLocationSearchSheet = true
                                        isKeyboardVisible = false
                                    },
                                    onEditing: {
                                        if !isKeyboardVisible {
                                            isKeyboardVisible = true
                                        }
                                    }
                                )
                            }
                            Divider()
                            HStack {
                                Button {
                                    showLocationSearchSheet = true
                                    isKeyboardVisible = false
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
                            onTagTap: { _ in isKeyboardVisible = false }
                        ) {
                            EndDateSelectorView(endDate: $repeatEndDate)
                        }
                        .padding(.bottom, 5)
                        .onChange(of: isRepeated) { newValue in
                            UIApplication.hideKeyboard()
                        }
                        TagToggleSection(
                            title: "알람",
                            tags: AlarmRule.tags,
                            isOn: $isAlarmOn,
                            selectedTag: $alarmRule
                        )
                        .padding(.bottom, 5)
                        .onChange(of: isAlarmOn) { newValue in
                            UIApplication.hideKeyboard()
                        }
                        HStack {
                            Text("배경색")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()

                            Button {
                                showColorPickerSheet = true
                                isKeyboardVisible = false
                            } label: {
                                ColorPicker("배경 색상 선택", selection: $previewColor)
                                    .labelsHidden()
                                    .disabled(true)
                            }
                        }
                        .sheet(isPresented: $showColorPickerSheet) {
                            ColorPickerView(selectedColorName: $selectedColorName)
                                .presentationDetents([.fraction(0.3)])

                        }
                        .onChange(of: selectedColorName) { newName in
                            previewColor = Color(newName)
                        }
                        Spacer()
                    }
                    .padding()
                }
                .padding(.bottom, 30)
                .onDisappear {
                    UIApplication.hideKeyboard()
                }
                .onAppear {
                    guard !didInit else { return }
                    startDate = Date().roundedUpToFiveMinutes()
                    endDate = Date().addingTimeInterval(3600).roundedUpToFiveMinutes()
                    didInit = true
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

            .overlay(alignment: .bottom) {
                VStack(spacing: 0) {
                    // 버튼 위로 덮일 페이드
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.0), location: 0.0),
                            .init(color: Color.white.opacity(1.0), location: 1.0),
                        ]),
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 28)

                    // 버튼
                    FilledButton(title: "저장하기", disabled: title.isEmpty) {
                        saveSchedule()
                        selectedTab = .plan
                        selectedCreationType = nil
                        dismiss()
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.ignoresSafeArea(edges: .bottom))
                }
            }
            .padding(.bottom, 8)

        }
    }
}

extension ManualScheduleInputView {
    @MainActor
    func saveSchedule() {
        Task { await saveSchedule() }
    }

    @MainActor
    func saveSchedule() async {
        let input = ScheduleInput(
            title: title,
            location: location,
            detail: detail,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            backgroundColorName: selectedColorName,
            repeatRuleName: isRepeated ? selectedRepeatRule?.name : nil,
            hasRepeatEndDate: hasRepeatEndDate,
            repeatEndDate: isRepeated ? repeatEndDate : nil,
            alarmRuleName: isAlarmOn ? alarmRule?.name : nil,
            isAlarmOn: isAlarmOn,
            isCompleted: false,
            eventIdentifier: eventIdentifier
        )

        do {
            let ids = try await editor.saveSchedule(input)
            lastSavedID = ids.first
        } catch {
            print("저장 실패: \(error)")
        }
        isSaving = false
    }
}

extension Date {
    /// 5분 단위 '올림' (초 단위도 함께 버림)
    func roundedUpToFiveMinutes() -> Date {
        let interval: TimeInterval = 5 * 60
        let t = timeIntervalSinceReferenceDate
        return Date(timeIntervalSinceReferenceDate: ceil(t / interval) * interval)
    }
}
