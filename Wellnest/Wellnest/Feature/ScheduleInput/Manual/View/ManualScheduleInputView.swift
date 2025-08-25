//
//  ScheduleCreateView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import SwiftUI
import CoreData

enum EditorMode: Equatable {
    case create
    case edit(objectID: NSManagedObjectID)
}

struct ManualScheduleInputView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: TabBarItem
    @Binding var selectedCreationType: ScheduleCreationType?

    @StateObject private var vm: ScheduleEditorViewModel

    @State private var isKeyboardVisible = true
    @State private var showLocationSearchSheet = false
    @State private var showColorPickerSheet = false
    @State private var showDeleteConfirm = false

    let onSaved: ((NSManagedObjectID) -> Void)?
    let onDeleted: (() -> Void)?

    init(
        mode: EditorMode,
        selectedTab: Binding<TabBarItem>,
        selectedCreationType: Binding<ScheduleCreationType?>,
        onSaved: ((NSManagedObjectID) -> Void)? = nil,
        onDeleted: (() -> Void)? = nil
    ) {
        _selectedTab = selectedTab
        _selectedCreationType = selectedCreationType
        _vm = StateObject(wrappedValue: ScheduleEditorFactory.make(mode: mode))
        self.onSaved = onSaved
        self.onDeleted = onDeleted
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: Spacing.layout) {
                        VStack {
                            titleTextField
                            locationSearchField
                        }
                        PeriodPickerView(
                            startDate: $vm.form.startDate,
                            endDate: $vm.form.endDate,
                            isAllDay: $vm.form.isAllDay
                        )
                        .padding(.bottom, 5)
                        TagToggleSection(
                            title: "반복",
                            tags: RepeatRule.tags,
                            isOn: $vm.form.isRepeated,
                            selectedTag: $vm.form.selectedRepeatRule,
                            showDetail: vm.form.selectedRepeatRule != nil,
                            onTagTap: { _ in isKeyboardVisible = false }
                        ) {
                            EndDateSelectorView(endDate: $vm.form.repeatEndDate)
                        }
                        .padding(.bottom, 5)
                        .onChange(of: vm.form.isRepeated) { newValue in
                            UIApplication.hideKeyboard()
                        }
                        TagToggleSection(
                            title: "알람",
                            tags: AlarmRule.tags,
                            isOn: $vm.form.isAlarmOn,
                            selectedTag: $vm.form.alarmRule
                        )
                        .padding(.bottom, 5)
                        .onChange(of: vm.form.isAlarmOn) { newValue in
                            isKeyboardVisible = false
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
                                ColorPicker("배경 색상 선택", selection: $vm.previewColor)
                                    .labelsHidden()
                                    .disabled(true)
                            }
                        }
                        .sheet(isPresented: $showColorPickerSheet) {
                            ColorPickerView(selectedColorName: $vm.form.selectedColorName)
                                .presentationDetents([.fraction(0.3)])

                        }
                        .onChange(of: vm.form.selectedColorName) { newName in
                            vm.updateColorName(newName)
                        }
                        Spacer()
                    }
                    .padding()
                }
                .padding(.bottom, 30)
                .task { await vm.loadIfNeeded() }
                .onDisappear {
                    isKeyboardVisible = false
                }
                .navigationTitle(vm.navTitle)
                .scrollDismissesKeyboard(.interactively)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            selectedCreationType = nil
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.wellnestOrange)
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 0) {
                    // 버튼 위로 덮일 페이드
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: colorScheme == .dark ? .black.opacity(0.0) : .white.opacity(0.0), location: 0.0),
                            .init(color:colorScheme == .dark ? .black : .white, location: 1.0),
                        ]),
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 28)

                    // 버튼
                    FilledButton(title: vm.primaryButtonTitle, disabled: vm.form.isTextEmpty) {
                        saveSchedule()
                        selectedTab = .plan
                        selectedCreationType = nil
                        dismiss()
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .background(colorScheme == .dark ? Color.black.ignoresSafeArea(edges: .bottom) : Color.white.ignoresSafeArea(edges: .bottom))
                }
            }
            .padding(.bottom, 8)

        }
    }

    @ViewBuilder
    private var titleTextField: some View {
        HStack {
            FocusableTextField(
                text: $vm.form.title,
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
    }

    @ViewBuilder
    private var locationSearchField: some View {
        HStack {
            Button {
                showLocationSearchSheet = true
                isKeyboardVisible = false
            } label: {
                HStack {
                    Text(vm.form.location.isEmpty ? "장소" : vm.form.location)
                        .foregroundStyle(vm.form.location.isEmpty ? .tertiary : .primary)
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
            LocationSearchView(
                selectedLocation: $vm.form.location,
                isPresented: $showLocationSearchSheet
            )
        }
        Divider()
    }
}

extension ManualScheduleInputView {
    @MainActor
    func saveSchedule() {
        Task {
            let id = try await vm.saveSchedule()
            onSaved?(id.first ?? NSManagedObjectID())
        }
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
