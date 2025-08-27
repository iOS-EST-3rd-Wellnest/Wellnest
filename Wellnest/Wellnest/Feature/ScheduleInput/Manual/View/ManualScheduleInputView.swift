//
//  ScheduleCreateView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import SwiftUI
import CoreData

struct ManualScheduleInputView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: TabBarItem
    @Binding var selectedCreationType: ScheduleCreationType?

    @StateObject private var viewModel: ScheduleEditorViewModel
    @ObservedObject var planVM: PlanViewModel

    @State private var isKeyboardVisible = true
    @State private var showLocationSearchSheet = false
    @State private var showColorPickerSheet = false
    @State private var showDeleteConfirmationSheet = false
    @State private var showAlert = false

    init(
        mode: EditorMode,
        selectedTab: Binding<TabBarItem>,
        selectedCreationType: Binding<ScheduleCreationType?>,
        planVM: PlanViewModel
    ) {
        _selectedTab = selectedTab
        _selectedCreationType = selectedCreationType
        _viewModel = StateObject(wrappedValue: ScheduleEditorFactory.make(mode: mode))
        self.planVM = planVM
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
                            startDate: $viewModel.form.startDate,
                            endDate: $viewModel.form.endDate,
                            isAllDay: $viewModel.form.isAllDay
                        )
                        .padding(.bottom, 5)
                        TagToggleSection(
                            title: "반복",
                            tags: RepeatRule.tags,
                            isOn: $viewModel.form.isRepeated,
                            selectedTag: $viewModel.form.selectedRepeatRule,
                            showDetail: viewModel.form.selectedRepeatRule != nil,
                            onTagTap: { _ in isKeyboardVisible = false }
                        ) {
                            EndDateSelectorView(mode: $viewModel.form.repeatEndMode, endDate: $viewModel.form.repeatEndDate)
                        }
                        .padding(.bottom, 5)
                        .onChange(of: viewModel.form.isRepeated) { newValue in
                            isKeyboardVisible = false
                        }
                        TagToggleSection(
                            title: "알람",
                            tags: AlarmRule.tags,
                            isOn: $viewModel.form.isAlarmOn,
                            selectedTag: $viewModel.form.alarmRule
                        )
                        .padding(.bottom, 5)
                        .onChange(of: viewModel.form.isAlarmOn) { newValue in
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
                                ColorPicker("배경 색상 선택", selection: $viewModel.previewColor)
                                    .labelsHidden()
                                    .disabled(true)
                            }
                        }
                        .sheet(isPresented: $showColorPickerSheet) {
                            ColorPickerView(selectedColorName: $viewModel.form.selectedColorName)
                                .presentationDetents([.fraction(0.3)])

                        }
                        .onChange(of: viewModel.form.selectedColorName) { newName in
                            viewModel.updateColorName(newName)
                        }
                        Spacer()
                    }
                    .padding()
                }
                .padding(.bottom, 30)
                .task {
                    await viewModel.loadIfNeeded()
                }
                .onAppear {
                    if selectedTab == .plan {
                        viewModel.form.startDate = planVM.combine(date: planVM.selectedDate)?.roundedUpToFiveMinutes() ?? Date()
                        viewModel.form.endDate   = viewModel.form.startDate.addingTimeInterval(3600).roundedUpToFiveMinutes()
                    } else {
                        viewModel.form.startDate = Date().roundedUpToFiveMinutes() 
                        viewModel.form.endDate   = Date().addingTimeInterval(3600).roundedUpToFiveMinutes()
                    }
                }
                .onDisappear {
                    isKeyboardVisible = false
                }
                .navigationTitle(viewModel.navigationBarTitle)
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
                    FilledButton(title: viewModel.primaryButtonTitle, disabled: viewModel.form.isTextEmpty) {
                        Task {
                            try await viewModel.saveSchedule()
                        }
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
                text: $viewModel.form.title,
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
                    Text(viewModel.form.location.isEmpty ? "장소" : viewModel.form.location)
                        .foregroundStyle(viewModel.form.location.isEmpty ? .tertiary : .primary)
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
                selectedLocation: $viewModel.form.location,
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
            let id = try await viewModel.saveSchedule()
        }
        selectedTab = .plan
        selectedCreationType = nil
        dismiss()
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
