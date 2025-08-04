//
//  AIScheduleInputView.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import SwiftUI

struct AIScheduleInputView: View {

    @StateObject private var alanService = AlanAIService()
    @State private var selectedPlanType: PlanType = .single
    @State private var selectedIntensity: String = "보통"
    @State private var selectedPreferences: Set<String> = []
    @State private var showResult: Bool = false

    // 단일 일정용
    @State private var singleDate = Date()
    @State private var singleStartTime = Date()
    @State private var singleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    // 여러 일정용
    @State private var multipleStartDate = Date()
    @State private var multipleEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var multipleStartTime = Date()
    @State private var multipleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    // 루틴용
    @State private var selectedWeekdays: Set<Int> = []
    @State private var routineStartDate = Date()
    @State private var routineEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var routineStartTime = Date()
    @State private var routineEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    private let intensityOptions = ["낮음", "보통", "높음"]
    private let preferenceOptions = ["유산소", "근력운동", "요가", "필라테스", "수영", "사이클링", "달리기", "등산"]
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    planTypeSection
                    dateTimeInputSection
                    intensitySection
                    preferencesSection
                    generateButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("플랜 생성")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showResult) {
                AIScheduleResultView(
                    healthPlan: alanService.healthPlan,
                    isLoading: alanService.isLoading,
                    errorMessage: alanService.errorMessage,
                    rawResponse: alanService.rawResponse
                )
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("맞춤 건강 플랜")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text("AI가 당신만의 건강 계획을 만들어드립니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var planTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("플랜 유형을 선택해주세요")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(PlanType.allCases, id: \.self) { planType in
                    PlanTypeCard(
                        planType: planType,
                        isSelected: selectedPlanType == planType
                    ) {
                        selectedPlanType = planType
                        // 플랜 타입 변경 시 기본값 설정
                        resetDateTimeValues()
                    }
                }
            }
        }
    }

    private var dateTimeInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch selectedPlanType {
            case .single:
                singlePlanDateTimeSection
            case .multiple:
                multiplePlanDateTimeSection
            case .routine:
                routinePlanDateTimeSection
            }
        }
    }

    // 단일 일정 입력 (날짜 + 시작시간 + 종료시간)
    private var singlePlanDateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("일정 설정")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                DatePicker("날짜", selection: $singleDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())

                DatePicker("시작 시간", selection: $singleStartTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(CompactDatePickerStyle())
                    .onChange(of: singleStartTime) { newValue in
                        // 시작 시간이 변경되면 종료 시간을 1시간 후로 자동 설정
                        singleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                    }

                DatePicker("종료 시간", selection: $singleEndTime, in: singleStartTime..., displayedComponents: .hourAndMinute)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // 여러 일정 입력 (시작날짜 + 종료날짜 + 시작시간 + 종료시간)
    private var multiplePlanDateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("기간 설정")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                DatePicker("시작 날짜", selection: $multipleStartDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())

                DatePicker("종료 날짜", selection: $multipleEndDate, in: multipleStartDate..., displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())

                Divider()

                Text("운동 시간대")
                    .font(.subheadline)
                    .fontWeight(.medium)

                DatePicker("시작 시간", selection: $multipleStartTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(CompactDatePickerStyle())
                    .onChange(of: multipleStartTime) { newValue in
                        // 시작 시간이 변경되면 종료 시간을 1시간 후로 자동 설정
                        multipleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                    }

                DatePicker("종료 시간", selection: $multipleEndTime, in: multipleStartTime..., displayedComponents: .hourAndMinute)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // 루틴 입력 (요일 + 시작시간 + 종료시간 + 루틴기간)
    private var routinePlanDateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("루틴 설정")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                // 요일 선택
                VStack(alignment: .leading, spacing: 8) {
                    Text("요일 선택")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            WeekdayChip(
                                weekday: weekdays[index],
                                index: index,
                                isSelected: selectedWeekdays.contains(index)
                            ) {
                                if selectedWeekdays.contains(index) {
                                    selectedWeekdays.remove(index)
                                } else {
                                    selectedWeekdays.insert(index)
                                }
                            }
                        }
                    }
                }

                Divider()

                // 운동 시간대
                VStack(alignment: .leading, spacing: 8) {
                    Text("운동 시간대")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    DatePicker("시작 시간", selection: $routineStartTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                        .onChange(of: routineStartTime) { newValue in
                            // 시작 시간이 변경되면 종료 시간을 1시간 후로 자동 설정
                            routineEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                        }

                    DatePicker("종료 시간", selection: $routineEndTime, in: routineStartTime..., displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                }

                Divider()

                // 루틴 기간
                VStack(alignment: .leading, spacing: 8) {
                    Text("루틴 기간")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    DatePicker("시작 날짜", selection: $routineStartDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())

                    DatePicker("종료 날짜", selection: $routineEndDate, in: routineStartDate..., displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("운동 강도")
                .font(.headline)
                .fontWeight(.semibold)

            Picker("강도 선택", selection: $selectedIntensity) {
                ForEach(intensityOptions, id: \.self) { intensity in
                    Text(intensity).tag(intensity)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("선호하는 운동 (복수 선택 가능)")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(preferenceOptions, id: \.self) { preference in
                    PreferenceChip(
                        title: preference,
                        isSelected: selectedPreferences.contains(preference)
                    ) {
                        if selectedPreferences.contains(preference) {
                            selectedPreferences.remove(preference)
                        } else {
                            selectedPreferences.insert(preference)
                        }
                    }
                }
            }
        }
    }

    private var generateButton: some View {
        Button(action: generatePlan) {
            HStack {
                if alanService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(alanService.isLoading ? "플랜 생성 중..." : "플랜 생성하기")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(buttonBackgroundColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isValidInput || alanService.isLoading)
    }

    private var buttonBackgroundColor: Color {
        (!isValidInput || alanService.isLoading) ? Color.gray : Color.blue
    }

    private var isValidInput: Bool {
        switch selectedPlanType {
        case .single:
            return singleEndTime > singleStartTime
        case .multiple:
            return multipleEndDate > multipleStartDate && multipleEndTime > multipleStartTime
        case .routine:
            return !selectedWeekdays.isEmpty && routineEndDate > routineStartDate && routineEndTime > routineStartTime
        }
    }

    private func resetDateTimeValues() {
        let now = Date()
        let oneHourLater = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now

        // 단일 일정 리셋
        singleDate = now
        singleStartTime = now
        singleEndTime = oneHourLater

        // 여러 일정 리셋
        multipleStartDate = now
        multipleEndDate = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        multipleStartTime = now
        multipleEndTime = oneHourLater

        // 루틴 리셋
        selectedWeekdays.removeAll()
        routineStartDate = now
        routineEndDate = Calendar.current.date(byAdding: .month, value: 1, to: now) ?? now
        routineStartTime = now
        routineEndTime = oneHourLater
    }

    private func generatePlan() {
        let request = createPlanRequest()
        alanService.generateHealthPlan(request)
        showResult = true
    }

    private func createPlanRequest() -> PlanRequest {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        var timeframe: String

        switch selectedPlanType {
        case .single:
            timeframe = """
            날짜: \(dateFormatter.string(from: singleDate))
            시간: \(timeFormatter.string(from: singleStartTime)) - \(timeFormatter.string(from: singleEndTime))
            """

        case .multiple:
            timeframe = """
            기간: \(dateFormatter.string(from: multipleStartDate)) ~ \(dateFormatter.string(from: multipleEndDate))
            운동시간: 매일 \(timeFormatter.string(from: multipleStartTime)) - \(timeFormatter.string(from: multipleEndTime))
            """

        case .routine:
            let selectedWeekdayNames = selectedWeekdays.sorted().map { weekdays[$0] }
            timeframe = """
            요일: 매주 \(selectedWeekdayNames.joined(separator: ", "))
            시간: \(timeFormatter.string(from: routineStartTime)) - \(timeFormatter.string(from: routineEndTime))
            기간: \(dateFormatter.string(from: routineStartDate)) ~ \(dateFormatter.string(from: routineEndDate))
            """
        }

        return PlanRequest(
            planType: selectedPlanType,
            userGoal: "온보딩에서 설정한 목표", // 온보딩에서 받을 예정
            timeframe: timeframe,
            preferences: Array(selectedPreferences),
            intensity: selectedIntensity
        )
    }
}

// MARK: - Supporting Views

struct PlanTypeCard: View {
    let planType: PlanType
    let isSelected: Bool
    let action: () -> Void

    private var cardIcon: String {
        switch planType {
        case .single: return "calendar.badge.plus"
        case .multiple: return "calendar"
        case .routine: return "repeat"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: cardIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)

                Text(planType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct PreferenceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}

struct WeekdayChip: View {
    let weekday: String
    let index: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(weekday)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .clipShape(Circle())
        }
    }
}

#Preview {
    AIScheduleInputView()
}
