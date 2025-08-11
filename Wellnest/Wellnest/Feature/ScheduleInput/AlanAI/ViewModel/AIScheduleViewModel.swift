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

    // 저장 관련 상태
    @Published var isSaving: Bool = false
    @Published var saveSuccess: Bool = false
    @Published var saveError: String = ""

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

    var currentViewState: ViewState {
        if isLoading {
            return .loading
        } else if !errorMessage.isEmpty {
            return .error
        } else if healthPlan != nil {
            return .content
        } else {
            return .empty
        }
    }

    // MARK: - Initialization
    init(userProfile: UserProfile = .default) {
        self.userProfile = userProfile
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
            .sink { [weak self] plan in
                self?.healthPlan = plan
                if plan != nil {
                    print("✅ HealthPlan 업데이트됨: \(plan?.title ?? "Unknown")")
                }
            }
            .store(in: &cancellables)
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
        print("🚀 generatePlan 호출됨")
        let request = createPlanRequest()
        aiService.generateHealthPlan(request, userProfile: userProfile)

        // 결과 화면 표시를 약간 지연시켜서 바인딩이 완료되도록 함
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showResult = true
            print("📱 showResult = true 설정됨")
        }
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

    // MARK: - 저장 로직
    func saveAISchedules() {
        guard let plan = healthPlan else {
            saveError = "저장할 플랜이 없습니다."
            return
        }

        print("💾 AI 스케줄 저장 시작")
        isSaving = true

        Task {
            do {
                try await saveSchedulesToCoreData(plan: plan)
                await MainActor.run {
                    isSaving = false
                    saveSuccess = true
                    print("✅ 저장 성공!")
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                    print("❌ 저장 실패: \(error)")
                }
            }
        }
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

    private func saveSchedulesToCoreData(plan: HealthPlanResponse) async throws {
        print("💿 Core Data 저장 시작 - 스케줄 개수: \(plan.schedules.count)")

        for (index, scheduleItem) in plan.schedules.enumerated() {
            let newSchedule = CoreDataService.shared.create(ScheduleEntity.self)
            newSchedule.id = UUID()
            newSchedule.title = scheduleItem.activity
            newSchedule.detail = scheduleItem.notes ?? ""

            // AIScheduleDateTimeHelper를 사용하여 날짜/시간 설정
            let dates = AIScheduleDateTimeHelper.parseDatesForCoreData(
                scheduleItem: scheduleItem,
                planType: plan.planType
            )
            newSchedule.startDate = dates.startDate
            newSchedule.endDate = dates.endDate

            newSchedule.isAllDay = false
            newSchedule.isCompleted = false
            newSchedule.repeatRule = plan.planType == "routine" ? "weekly" : nil
            newSchedule.hasRepeatEndDate = false
            newSchedule.repeatEndDate = nil
            newSchedule.alarm = nil
            newSchedule.scheduleType = "ai_generated"
            newSchedule.createdAt = Date()
            newSchedule.updatedAt = Date()

            print("📝 AI 스케줄 \(index + 1) 생성: \(newSchedule.title ?? "제목없음") - 시작: \(newSchedule.startDate ?? Date()) - 종료: \(newSchedule.endDate ?? Date())")
        }

        try CoreDataService.shared.saveContext()
        print("💾 Core Data 저장 완료")
    }

    // 헬퍼 메서드들 추가
    private func parseTime(from timeString: String) -> (hour: Int, minute: Int) {
        let cleanTime = timeString.components(separatedBy: "-")[0].trimmingCharacters(in: .whitespaces)
        let components = cleanTime.components(separatedBy: ":")

        if components.count >= 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            return (hour: hour, minute: minute)
        }

        return (hour: 9, minute: 0) // 기본값
    }

    private func parseEndTime(from timeString: String) -> (hour: Int, minute: Int) {
        if timeString.contains("-") {
            let timeComponents = timeString.components(separatedBy: "-")
            if timeComponents.count >= 2 {
                let endTimeString = timeComponents[1].trimmingCharacters(in: .whitespaces)
                return parseTime(from: endTimeString)
            }
        }

        // 기본값: 시작 시간 + 1시간
        let startTime = parseTime(from: timeString)
        return (hour: min(startTime.hour + 1, 23), minute: startTime.minute)
    }

    private func getNextDate(for dayString: String) -> Date? {
        let calendar = Calendar.current
        let today = Date()

        let weekdayMapping: [String: Int] = [
            "일요일": 1, "월요일": 2, "화요일": 3, "수요일": 4,
            "목요일": 5, "금요일": 6, "토요일": 7
        ]

        guard let targetWeekday = weekdayMapping[dayString] else {
            return today
        }

        let currentWeekday = calendar.component(.weekday, from: today)
        var daysToAdd = targetWeekday - currentWeekday

        if daysToAdd <= 0 {
            daysToAdd += 7 // 다음 주
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: today)
    }

    // MARK: - View State Enum
    enum ViewState {
        case loading
        case error
        case content
        case empty
    }
}
