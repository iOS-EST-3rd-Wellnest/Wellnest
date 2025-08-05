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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    PlanHeaderSection()

                    PlanTypeSelectionSection(
                        selectedPlanType: $selectedPlanType,
                        onPlanTypeChanged: resetDateTimeValues
                    )

                    dateTimeInputSection

                    PreferencesSelectionSection(selectedPreferences: $selectedPreferences)

                    generateButton
                        .padding(.top, 20)
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

    private var dateTimeInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch selectedPlanType {
            case .single:
                SinglePlanDateTimeSection(
                    singleDate: $singleDate,
                    singleStartTime: $singleStartTime,
                    singleEndTime: $singleEndTime
                )
            case .multiple:
                MultiplePlanDateTimeSection(
                    multipleStartDate: $multipleStartDate,
                    multipleEndDate: $multipleEndDate,
                    multipleStartTime: $multipleStartTime,
                    multipleEndTime: $multipleEndTime
                )
            case .routine:
                RoutinePlanDateTimeSection(
                    selectedWeekdays: $selectedWeekdays,
                    routineStartDate: $routineStartDate,
                    routineEndDate: $routineEndDate,
                    routineStartTime: $routineStartTime,
                    routineEndTime: $routineEndTime
                )
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
        PlanValidationHelper.isValidInput(
            planType: selectedPlanType,
            singleStartTime: singleStartTime,
            singleEndTime: singleEndTime,
            multipleStartDate: multipleStartDate,
            multipleEndDate: multipleEndDate,
            multipleStartTime: multipleStartTime,
            multipleEndTime: multipleEndTime,
            selectedWeekdays: selectedWeekdays,
            routineStartDate: routineStartDate,
            routineEndDate: routineEndDate,
            routineStartTime: routineStartTime,
            routineEndTime: routineEndTime
        )
    }

    // MARK: - Helper Methods

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
        return PlanRequestFactory.createPlanRequest(
            planType: selectedPlanType,
            selectedPreferences: selectedPreferences,
            singleDate: singleDate,
            singleStartTime: singleStartTime,
            singleEndTime: singleEndTime,
            multipleStartDate: multipleStartDate,
            multipleEndDate: multipleEndDate,
            multipleStartTime: multipleStartTime,
            multipleEndTime: multipleEndTime,
            selectedWeekdays: selectedWeekdays,
            routineStartDate: routineStartDate,
            routineEndDate: routineEndDate,
            routineStartTime: routineStartTime,
            routineEndTime: routineEndTime
        )
    }
}

#Preview {
    AIScheduleInputView()
}
