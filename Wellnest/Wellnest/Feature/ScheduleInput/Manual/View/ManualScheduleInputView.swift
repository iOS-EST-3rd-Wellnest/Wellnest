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

    enum InputField: Hashable {
        case title
        case note
    }
    @State private var currentFocus: InputField? = .title

    @State private var isKeyboardVisible = true
    @State private var showLocationSearchSheet = false
    @State private var showColorPickerSheet = false
    @State private var showOnlySeriesItemEditMenu = false
    @State private var isChangedRepeatRule = false
    @State private var showMenu = false
    @State private var showDeleteAlert = false
    @State private var showDeleteSeriesAlert = false

    @State private var showNote = false
    @State private var didInit = false

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
                            isAllDay: $viewModel.form.isAllDay,
                            onButtonTap: {
                                currentFocus = nil
                            }
                        )
                        .onChange(of: viewModel.form.isAllDay) { _ in
                            currentFocus = nil
                        }
                        .padding(.bottom, 5)
                        TagToggleSection(
                            title: "반복",
                            tags: RepeatRule.tags,
                            isOn: $viewModel.form.isRepeated,
                            selectedTag: $viewModel.form.selectedRepeatRule,
                            showDetail: viewModel.form.selectedRepeatRule != nil,
                            onTagTap: { _ in
                                currentFocus = nil
                            }
                        ) {
                            EndDateSelectorView(
                                mode: $viewModel.form.repeatEndMode,
                                endDate: $viewModel.form.repeatEndDate
                            )
                        }
                        .padding(.bottom, 5)
                        .onChange(of: viewModel.form.isRepeated) { _ in
                            currentFocus = nil
                        }
                        .onChange(of: viewModel.form.selectedRepeatRule) { newValue in
                            if viewModel.isEditMode && viewModel.form.isRepeated {
                                isChangedRepeatRule = true
                            }
                        }
                        TagToggleSection(
                            title: "알람",
                            tags: AlarmRule.tags,
                            isOn: $viewModel.form.isAlarmOn,
                            selectedTag: $viewModel.form.alarmRule
                        )
                        .padding(.bottom, 5)
                        .onChange(of: viewModel.form.isAlarmOn) { _ in
                            currentFocus = nil
                        }
                        HStack {
                            Text("색상")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()

                            Button {
                                showColorPickerSheet = true
                                currentFocus = nil
                            } label: {
                                ColorPicker("팔레트 선택", selection: $viewModel.previewColor)
                                    .labelsHidden()
                                    .disabled(true)
                            }
                        }
                        .padding(.bottom, 5)
                        .sheet(isPresented: $showColorPickerSheet) {
                            ColorPickerView(selectedColorName: $viewModel.form.selectedColorName)
                                .presentationDetents([.fraction(0.3)])
                        }
                        .onChange(of: viewModel.form.selectedColorName) { newName in
                            viewModel.updateColorName(newName)
                        }
                        DisclosureGroup {
                            noteTextField
                        } label: {
                            Text("메모")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .tint(.black)
                        .onTapGesture {
                            withAnimation { showNote.toggle() }
                        }
//                        .onChange(of: showNote) { open in
//                            if open {
//                                DispatchQueue.main.async {
//                                    FocusableTextField = .note
//                                }
//                            } else if focusField == .note {
//                                focusField = nil
//                            }
//                        }
                        Spacer()
                    }
                    .padding()
                }
                .padding(.bottom, 80)
                .task {
                    await viewModel.loadIfNeeded()
                    if viewModel.isEditMode {
                        currentFocus = nil
                    }
                }
                .onAppear {

                    guard !didInit else { return }
                    if selectedTab == .plan {
                        // 플랜탭일 때.
                        let selectedDate = viewModel.combine(date: planVM.selectedDate)?.roundedUpToFiveMinutes() ?? Date()
                        viewModel.setDefaultDate(for: selectedDate)
                    }
                    didInit = true
                }
                .onDisappear {
                    currentFocus = nil
                }
                .onChange(of: viewModel.form.startDate) { _ in
                    currentFocus = nil
                }
                .onChange(of: viewModel.form.endDate) { _ in
                    currentFocus = nil
                }
//                .onChange(of: focusField) { f in
//                    isKeyboardVisible = (f != nil)
//                }
                .navigationTitle(viewModel.navigationBarTitle)
                .scrollDismissesKeyboard(.interactively)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if viewModel.isEditMode {
                            closeTapBarButton
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if viewModel.isEditMode {
                            if viewModel.form.isRepeated {
                                deleteRepeatScheduleTapBarButton
                            } else {
                                deleteTapBarButton
                            }
                        } else {
                            closeTapBarButton
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

                    ZStack(alignment: .bottom) {
                        // 버튼
                        FilledButton(title: viewModel.primaryButtonTitle,
                                     disabled: viewModel.form.isTextEmpty
                        ) {
                            // 편집 모드일 때
                            if viewModel.isEditMode {

                                // 반복 아이탬일 경우
                                // 또는 반복 아이탬은 아니지만 반복 체크를 한 경우

                                if viewModel.form.isRepeated || isChangedRepeatRule {
                                    withAnimation {
                                        // 이후 아이탬에 대해 수정 메뉴 띄우기
                                        showOnlySeriesItemEditMenu.toggle()
                                    }
                                }
                                // 반복 아이탬이 아니며, 수정된 내용이 반복 규칙이 아닌 경우
                                else {
                                    Task {
                                        // 단순 스케줄 업데이트
                                        try await viewModel.saveSchedule()
                                        currentFocus = nil
                                        selectedTab = .plan
                                        selectedCreationType = nil
                                        dismiss()
                                    }
                                }
                            } else {
                                Task {
                                    try await viewModel.saveSchedule()
                                    currentFocus = nil
                                    selectedTab = .plan
                                    selectedCreationType = nil
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .background(colorScheme == .dark
                                    ? Color.black.ignoresSafeArea(edges: .bottom)
                                    : Color.white.ignoresSafeArea(edges: .bottom))

                        if showOnlySeriesItemEditMenu {
                            VStack(spacing: 0) {
                                Section(header:
                                    Text("반복되는 이벤트입니다.")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 6)

                                ) {
                                    Divider()
                                    Button("이후 이벤트에 대해 저장") {
                                        // 반복 이벤트로 바뀜
                                        if isChangedRepeatRule {
                                            Task {
                                                try await viewModel.updateRepeatRule()
                                            }
                                        } else {
                                            // 반복 이벤트에 대해서 전부 수정
                                            Task {
                                                try await viewModel.updateRepeatSeries()
                                            }
                                        }
                                        showOnlySeriesItemEditMenu = false
                                        selectedTab = .plan
                                        selectedCreationType = nil
                                        currentFocus = nil
                                        dismiss()
                                    }
                                    .padding()
                                }
                            }
                            .foregroundColor(.black)
                            .background(RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground)))
                            .shadow(radius: 0.5)
                            .frame(width: 200)
                            .offset(y: -70)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9, anchor: .bottom).combined(with: .opacity),
                                removal:   .opacity
                            ))
                        }
                    }
                    .animation(.spring(response: 0.22, dampingFraction: 0.85), value: showMenu)

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
                isFirstResponder: currentFocus == .title,
                returnKeyType: .next,
                keyboardType: .default,
                onReturn: {
                    showLocationSearchSheet = true
                    currentFocus = nil
                },
                onEditing: {
                    if currentFocus != .title {
                        currentFocus = .title
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
                currentFocus = nil
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

    @ViewBuilder
    private var noteTextField: some View {
        HStack {
            FocusableTextField(
                text: $viewModel.form.detail,
                placeholder: "메모를 입력하세요.",
                isFirstResponder: currentFocus == .note,
                returnKeyType: .done,
                keyboardType: .default,
                onReturn: {
                    currentFocus = nil
                },
                onEditing: {
                    if currentFocus != .note {
                        currentFocus = .note
                    }
                }
            )
            .padding(.top, 8)
        }
        Divider()
    }
    @ViewBuilder
    private var closeTapBarButton: some View {
        Button {
            currentFocus = nil
            selectedCreationType = nil
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundColor(.wellnestOrange)
        }
    }

    @ViewBuilder
    private var deleteRepeatScheduleTapBarButton: some View {
        Menu {
            Section("반복되는 이벤트입니다.") {
                Button("이 이벤트만 삭제") {
                    showDeleteAlert = true
                    currentFocus = nil

                }

                Button("이후 모든 이벤트 삭제") {
                    showDeleteSeriesAlert = true
                    currentFocus = nil
                }
            }
        } label: {
            Image(systemName: "trash")
                .foregroundColor(.red)
        }
        .alert("정말로 삭제하시겠습니까?", isPresented: $showDeleteSeriesAlert) {
            Button("삭제", role: .destructive) {
                showDeleteSeriesAlert = false
                currentFocus = nil
                Task {
                    try await viewModel.deleteFollowingInSeries()
                    selectedTab = .plan
                    selectedCreationType = nil
                    dismiss()
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("이 작업은 되돌릴 수 없습니다.")
        }
        .alert("정말로 삭제하시겠습니까?", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                showDeleteAlert = false
                currentFocus = nil
                Task {
                    try await viewModel.delete()
                    selectedTab = .plan
                    selectedCreationType = nil
                    dismiss()
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("이 작업은 되돌릴 수 없습니다.")
        }
    }

    @ViewBuilder
    var deleteTapBarButton: some View {
        Button {
            showDeleteAlert = true
            currentFocus = nil
        } label: {
            Image(systemName: "trash")
                .foregroundColor(.red)
        }
        .alert("정말로 삭제하시겠습니까?", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                showDeleteAlert = false
                currentFocus = nil
                Task {
                    try await viewModel.delete()
                    selectedTab = .plan
                    selectedCreationType = nil
                    dismiss()
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("이 작업은 되돌릴 수 없습니다.")
        }
    }
}

extension ManualScheduleInputView {
    @MainActor
    func saveSchedule() {
        Task {
            let _ = try await viewModel.saveSchedule()
        }
        currentFocus = nil
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
