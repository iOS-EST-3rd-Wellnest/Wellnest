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

    private func saveSchedulesToCoreData(plan: HealthPlanResponse) async throws {
        print("💿 Core Data 저장 시작 - 스케줄 개수: \(plan.schedules.count)")

        for (index, scheduleItem) in plan.schedules.enumerated() {
            let newSchedule = CoreDataService.shared.create(ScheduleEntity.self)
            newSchedule.id = UUID()
            newSchedule.title = scheduleItem.activity
            newSchedule.detail = scheduleItem.notes ?? ""

            // AI 스케줄의 날짜와 시간 설정
            if let dateString = scheduleItem.date {
                // 특정 날짜가 있는 경우
                newSchedule.startDate = parseDate(from: dateString, time: scheduleItem.time)
                newSchedule.endDate = parseEndDate(from: dateString, time: scheduleItem.time)
            } else if let dayString = scheduleItem.day {
                // 요일 기반인 경우 (루틴)
                newSchedule.startDate = getNextDate(for: dayString, time: scheduleItem.time)
                newSchedule.endDate = parseEndDate(from: nil, time: scheduleItem.time, baseDate: newSchedule.startDate)
            } else {
                // 기본값
                newSchedule.startDate = Date()
                newSchedule.endDate = Date().addingTimeInterval(3600)
            }

            newSchedule.isAllDay = false
            newSchedule.isCompleted = false
            newSchedule.repeatRule = plan.planType == "routine" ? "weekly" : nil
            newSchedule.hasRepeatEndDate = false
            newSchedule.repeatEndDate = nil
            newSchedule.alarm = nil
            newSchedule.scheduleType = "ai_generated"
            newSchedule.createdAt = Date()
            newSchedule.updatedAt = Date()

            print("📝 AI 스케줄 \(index + 1) 생성: \(newSchedule.title ?? "제목없음") - \(newSchedule.startDate ?? Date())")
        }

        try CoreDataService.shared.saveContext()
        print("💾 Core Data 저장 완료")
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

    // 날짜/시간 파싱 헬퍼 메서드들
    private func parseDate(from dateString: String?, time: String) -> Date {
        let calendar = Calendar.current
        let now = Date()

        // 시간 파싱
        let timeComponents = parseTime(from: time)

        if let dateString = dateString {
            // 특정 날짜가 있는 경우
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko_KR")
            dateFormatter.dateFormat = "yyyy-MM-dd"

            if let date = dateFormatter.date(from: dateString) {
                return calendar.date(bySettingHour: timeComponents.hour,
                                   minute: timeComponents.minute,
                                   second: 0,
                                   of: date) ?? now
            }
        }

        // 기본값: 오늘 날짜에 시간 설정
        return calendar.date(bySettingHour: timeComponents.hour,
                           minute: timeComponents.minute,
                           second: 0,
                           of: now) ?? now
    }

    private func parseEndDate(from dateString: String?, time: String, baseDate: Date? = nil) -> Date {
        let startDate = baseDate ?? parseDate(from: dateString, time: time)

        // 시간 범위 파싱 (예: "09:00 - 10:00")
        if time.contains("-") {
            let timeComponents = time.components(separatedBy: "-")
            if timeComponents.count == 2 {
                let endTimeString = timeComponents[1].trimmingCharacters(in: .whitespaces)
                let endTimeComponents = parseTime(from: endTimeString)

                let calendar = Calendar.current
                return calendar.date(bySettingHour: endTimeComponents.hour,
                                   minute: endTimeComponents.minute,
                                   second: 0,
                                   of: startDate) ?? startDate.addingTimeInterval(3600)
            }
        }

        // 기본값: 1시간 후
        return startDate.addingTimeInterval(3600)
    }

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

    private func getNextDate(for dayString: String, time: String) -> Date {
        let calendar = Calendar.current
        let today = Date()

        let weekdayMapping: [String: Int] = [
            "일요일": 1, "월요일": 2, "화요일": 3, "수요일": 4,
            "목요일": 5, "금요일": 6, "토요일": 7
        ]

        guard let targetWeekday = weekdayMapping[dayString] else {
            return parseDate(from: nil, time: time)
        }

        let currentWeekday = calendar.component(.weekday, from: today)
        var daysToAdd = targetWeekday - currentWeekday

        if daysToAdd <= 0 {
            daysToAdd += 7 // 다음 주
        }

        let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
        return parseDate(from: nil, time: time)
    }

    // MARK: - View State Enum
    enum ViewState {
        case loading
        case error
        case content
        case empty
    }
}
