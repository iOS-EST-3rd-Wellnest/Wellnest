//
//  AIScheduleViewModel.swift
//  Wellnest
//
//  Created by junil on 8/6/25.
//

import Foundation
import Combine
import UIKit

@MainActor
final class AIScheduleViewModel: ObservableObject {
    // MARK: - Published Properties (View State)
    @Published var selectedPlanType: PlanType = .single
    @Published var selectedPreferences: Set<String> = []
    @Published var showResult: Bool = false

    // 단일 일정용
    @Published var singleDate = Date()
    @Published var singleStartTime = Date()
    @Published var singleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    // 여러 일정용
    @Published var multipleStartDate = Date()
    @Published var multipleEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @Published var multipleStartTime = Date()
    @Published var multipleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    // 루틴용
    @Published var selectedWeekdays: Set<Int> = []
    @Published var routineStartDate = Date()
    @Published var routineEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @Published var routineStartTime = Date()
    @Published var routineEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    // AI Service State
    @Published var healthPlan: HealthPlanResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var rawResponse: String = ""

    // MARK: - Dependencies
    private lazy var aiService = AlanAIService()
    private let userProfile: UserProfile
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var isValidInput: Bool {
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

    var buttonBackgroundColor: UIColor {
        (!isValidInput || isLoading) ? UIColor.gray : UIColor.systemBlue
    }

    // MARK: - Initialization
    init(userProfile: UserProfile = .default) {
        self.userProfile = userProfile
    }

    // MARK: - Setup
    private func setupBindingsIfNeeded() {
        guard cancellables.isEmpty else { return }
        setupBindings()
    }

    // MARK: - Private Methods
    private func setupBindings() {
        // AI Service의 상태를 ViewModel에 바인딩
        aiService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        aiService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)

        aiService.$rawResponse
            .receive(on: DispatchQueue.main)
            .assign(to: &$rawResponse)

        aiService.$healthPlan
            .receive(on: DispatchQueue.main)
            .assign(to: &$healthPlan)
    }

    // MARK: - Public Methods
    func resetDateTimeValues() {
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

    func generatePlan() {
        setupBindingsIfNeeded()
        let request = createPlanRequest()
        aiService.generateHealthPlan(request, userProfile: userProfile)
        showResult = true
    }

    func updateSingleStartTime(_ newTime: Date) {
        singleStartTime = newTime
        singleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newTime) ?? newTime
    }

    func updateMultipleStartTime(_ newTime: Date) {
        multipleStartTime = newTime
        multipleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newTime) ?? newTime
    }

    func updateRoutineStartTime(_ newTime: Date) {
        routineStartTime = newTime
        routineEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newTime) ?? newTime
    }

    func togglePreference(_ preference: String) {
        if selectedPreferences.contains(preference) {
            selectedPreferences.remove(preference)
        } else {
            selectedPreferences.insert(preference)
        }
    }

    func toggleWeekday(_ index: Int) {
        if selectedWeekdays.contains(index) {
            selectedWeekdays.remove(index)
        } else {
            selectedWeekdays.insert(index)
        }
    }

    func selectPlanType(_ planType: PlanType) {
        selectedPlanType = planType
        resetDateTimeValues()
    }

    // MARK: - Private Helpers
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
