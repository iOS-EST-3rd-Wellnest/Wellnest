//
//  AIScheduleViewModel.swift
//  Wellnest
//
//  Created by junil on 8/6/25.
//

import Foundation
import Combine
import UIKit
import EventKit

@MainActor
final class AIScheduleViewModel: ObservableObject {
    @Published var selectedPlanType: PlanType = .single
    @Published var selectedPreferences: Set<String> = []
    @Published var showResult: Bool = false

    @Published var singleDate = Date()
    @Published var singleStartTime = Date()
    @Published var singleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    @Published var multipleStartDate = Date()
    @Published var multipleEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @Published var multipleStartTime = Date()
    @Published var multipleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    @Published var selectedWeekdays: Set<Int> = []
    @Published var routineStartDate = Date()
    @Published var routineEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @Published var routineStartTime = Date()
    @Published var routineEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    @Published var healthPlan: HealthPlanResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var rawResponse: String = ""

    @Published var isSaving: Bool = false
    @Published var saveSuccess: Bool = false
    @Published var saveError: String = ""

    // AI 생성 일정을 담아놓는 배열
    @Published var generatedPlans: [GeneratedPlanItem] = []

    // UserInfoViewModel 추가
    let userInfoViewModel: UserInfoViewModel

    // MARK: - AI 생성 일정 구조
    struct GeneratedPlanItem {
        enum Kind {
            case single
            case multiple
            case routine(weekdays: [Int])
        }

        let title: String
        let location: String?
        let memo: String?
        let startDate: Date
        let endDate: Date?
        let isAllDay: Bool
        let kind: Kind
        let seriesEndDate: Date?
    }

    private lazy var aiService = AlanAIService()
    private let userProfile: UserProfile
    private var cancellables = Set<AnyCancellable>()

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

    init(userProfile: UserProfile = .default, userInfoViewModel: UserInfoViewModel? = nil) {
        self.userProfile = userProfile
        self.userInfoViewModel = userInfoViewModel ?? UserInfoViewModel()
        setupBindings()
    }

    private func setupBindings() {
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
                    print("HealthPlan 업데이트됨: \(plan?.title ?? "Unknown")")
                }
            }
            .store(in: &cancellables)
    }

    func resetDateTimeValues() {
        let now = Date()
        let oneHourLater = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now

        singleDate = now
        singleStartTime = now
        singleEndTime = oneHourLater

        multipleStartDate = now
        multipleEndDate = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        multipleStartTime = now
        multipleEndTime = oneHourLater

        selectedWeekdays.removeAll()
        routineStartDate = now
        routineEndDate = Calendar.current.date(byAdding: .month, value: 1, to: now) ?? now
        routineStartTime = now
        routineEndTime = oneHourLater
    }

    func generatePlan() {
        print("generatePlan 호출됨")
        let request = createPlanRequest()
        aiService.generateHealthPlan(request, userProfile: userProfile)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showResult = true
            print("showResult = true 설정됨")
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

    // MARK: - 올바른 날짜/시간 생성 헬퍼 메서드
    private func createCorrectDatesForSchedule(scheduleIndex: Int, totalSchedules: Int) -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current

        switch selectedPlanType {
        case .single:
            // 선택한 날짜와 시간 조합
            let startDateTime = calendar.date(
                bySettingHour: calendar.component(.hour, from: singleStartTime),
                minute: calendar.component(.minute, from: singleStartTime),
                second: 0,
                of: singleDate
            ) ?? singleDate

            let endDateTime = calendar.date(
                bySettingHour: calendar.component(.hour, from: singleEndTime),
                minute: calendar.component(.minute, from: singleEndTime),
                second: 0,
                of: singleDate
            ) ?? singleDate.addingTimeInterval(3600)

            return (startDateTime, endDateTime)

        case .multiple:
            // 여러 일정을 날짜 범위에 분배
            let totalDays = Int(multipleEndDate.timeIntervalSince(multipleStartDate) / (24 * 3600)) + 1
            
            if totalDays == 1 {
                // 같은 날이면 시간대별로 분배
                let totalMinutes = Int(multipleEndTime.timeIntervalSince(multipleStartTime) / 60)
                let minutesPerSchedule = max(30, totalMinutes / totalSchedules)
                
                let timeOffset = minutesPerSchedule * scheduleIndex
                let adjustedStartTime = calendar.date(byAdding: .minute, value: timeOffset, to: multipleStartTime) ?? multipleStartTime
                let adjustedEndTime = calendar.date(byAdding: .minute, value: minutesPerSchedule, to: adjustedStartTime) ?? adjustedStartTime
                
                let startDateTime = calendar.date(
                    bySettingHour: calendar.component(.hour, from: adjustedStartTime),
                    minute: calendar.component(.minute, from: adjustedStartTime),
                    second: 0,
                    of: multipleStartDate
                ) ?? multipleStartDate
                
                let endDateTime = calendar.date(
                    bySettingHour: calendar.component(.hour, from: adjustedEndTime),
                    minute: calendar.component(.minute, from: adjustedEndTime),
                    second: 0,
                    of: multipleStartDate
                ) ?? multipleStartDate.addingTimeInterval(3600)
                
                return (startDateTime, endDateTime)
            } else {
                // 다른 날이면 모든 일정을 시작날짜에 배치하되 시간대별로 분배
                let targetDate = multipleStartDate
                
                // 시간대별로 분배 로직 추가
                let totalMinutes = Int(multipleEndTime.timeIntervalSince(multipleStartTime) / 60)
                let minutesPerSchedule = max(30, totalMinutes / totalSchedules)
                
                let timeOffset = minutesPerSchedule * scheduleIndex
                let adjustedStartTime = calendar.date(byAdding: .minute, value: timeOffset, to: multipleStartTime) ?? multipleStartTime
                let adjustedEndTime = calendar.date(byAdding: .minute, value: minutesPerSchedule, to: adjustedStartTime) ?? adjustedStartTime
                
                let startDateTime = calendar.date(
                    bySettingHour: calendar.component(.hour, from: adjustedStartTime),
                    minute: calendar.component(.minute, from: adjustedStartTime),
                    second: 0,
                    of: targetDate
                ) ?? targetDate
                
                let endDateTime = calendar.date(
                    bySettingHour: calendar.component(.hour, from: adjustedEndTime),
                    minute: calendar.component(.minute, from: adjustedEndTime),
                    second: 0,
                    of: targetDate
                ) ?? targetDate.addingTimeInterval(3600)
                
                return (startDateTime, endDateTime)
            }

        case .routine:
            // 루틴의 경우: AI 응답의 실제 요일과 시간을 사용
            guard let plan = healthPlan, scheduleIndex < plan.schedules.count else {
                // 기본값 반환
                let startDateTime = calendar.date(
                    bySettingHour: calendar.component(.hour, from: routineStartTime),
                    minute: calendar.component(.minute, from: routineStartTime),
                    second: 0,
                    of: routineStartDate
                ) ?? routineStartDate

                let endDateTime = calendar.date(
                    bySettingHour: calendar.component(.hour, from: routineEndTime),
                    minute: calendar.component(.minute, from: routineEndTime),
                    second: 0,
                    of: routineStartDate
                ) ?? routineStartDate.addingTimeInterval(3600)

                return (startDateTime, endDateTime)
            }

            let scheduleItem = plan.schedules[scheduleIndex]

            if let dayString = scheduleItem.day {
                let targetDate = getNextDate(for: dayString) ?? routineStartDate
                let timeComponents = parseTime(from: scheduleItem.time)
                let endTimeComponents = parseEndTime(from: scheduleItem.time)

                print("🔍 targetDate: \(targetDate)")
                print("🔍 timeComponents: \(timeComponents)")

                // 더 직접적인 접근: 날짜의 시작부터 계산
                let calendar = Calendar.current
                let startOfTargetDay = calendar.startOfDay(for: targetDate)

                print("🔍 startOfTargetDay: \(startOfTargetDay)")

                let startDateTime = calendar.date(byAdding: .hour, value: timeComponents.hour, to: startOfTargetDay)!
                    .addingTimeInterval(TimeInterval(timeComponents.minute * 60))

                let endDateTime = calendar.date(byAdding: .hour, value: endTimeComponents.hour, to: startOfTargetDay)!
                    .addingTimeInterval(TimeInterval(endTimeComponents.minute * 60))

                print("🔍 최종 계산된 startDateTime: \(startDateTime)")
                print("🔍 최종 계산된 endDateTime: \(endDateTime)")

                return (startDateTime, endDateTime)

            } else {
                // day가 없는 경우 기본 처리
                let timeComponents = parseTime(from: scheduleItem.time)
                let endTimeComponents = parseEndTime(from: scheduleItem.time)

                let startDateTime = calendar.date(
                    bySettingHour: timeComponents.hour,
                    minute: timeComponents.minute,
                    second: 0,
                    of: routineStartDate
                ) ?? routineStartDate

                let endDateTime = calendar.date(
                    bySettingHour: endTimeComponents.hour,
                    minute: endTimeComponents.minute,
                    second: 0,
                    of: routineStartDate
                ) ?? routineStartDate.addingTimeInterval(3600)

                return (startDateTime, endDateTime)
            }
        }
    }

    private func saveSchedulesToCoreData(plan: HealthPlanResponse) async throws {
        //print("Core Data 저장 시작 - 스케줄 개수: \(plan.schedules.count)")

        for (index, scheduleItem) in plan.schedules.enumerated() {
            let newSchedule = CoreDataService.shared.create(ScheduleEntity.self)
            newSchedule.id = UUID()
            newSchedule.title = scheduleItem.activity
            newSchedule.detail = scheduleItem.notes ?? ""

            // 수정: 올바른 날짜/시간 사용
            let dates = createCorrectDatesForSchedule(scheduleIndex: index, totalSchedules: plan.schedules.count)
            newSchedule.startDate = dates.startDate
            newSchedule.endDate = dates.endDate

            newSchedule.isAllDay = false
            newSchedule.isCompleted = false
            newSchedule.repeatRule = plan.planType == "routine" ? "매주" : nil
            newSchedule.hasRepeatEndDate = false
            newSchedule.repeatEndDate = nil
            newSchedule.alarm = nil
            newSchedule.scheduleType = "ai_generated"
            newSchedule.createdAt = Date()
            newSchedule.updatedAt = Date()

            //print("AI 스케줄 \(index + 1) 생성: \(newSchedule.title ?? "제목없음") - 시작: \(dates.startDate) - 종료: \(dates.endDate)")
        }

        try CoreDataService.shared.saveContext()
        //print("Core Data 저장 완료")
    }

    private func parseTime(from timeString: String) -> (hour: Int, minute: Int) {
        let cleanTime = timeString.components(separatedBy: "-")[0].trimmingCharacters(in: .whitespaces)
        let components = cleanTime.components(separatedBy: ":")

        if components.count >= 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            return (hour: hour, minute: minute)
        }

        return (hour: 9, minute: 0)
    }

    private func parseEndTime(from timeString: String) -> (hour: Int, minute: Int) {
        if timeString.contains("-") {
            let timeComponents = timeString.components(separatedBy: "-")
            if timeComponents.count >= 2 {
                let endTimeString = timeComponents[1].trimmingCharacters(in: .whitespaces)
                return parseTime(from: endTimeString)
            }
        }

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

        if daysToAdd < 0 {
            daysToAdd += 7
        }

        // 단순히 날짜만 더하고, 시간 조작은 하지 않기
        return calendar.date(byAdding: .day, value: daysToAdd, to: today)
    }

    enum ViewState {
        case loading
        case error
        case content
        case empty
    }


    func saveAISchedules() {
        guard let plan = healthPlan else {
            saveError = "저장할 플랜이 없습니다."
            return
        }

        print("AI 스케줄 저장 시작")
        isSaving = true

        Task {
            do {
                // CoreData만 사용
                try await saveSchedulesToCoreDataOnly(plan: plan)

                await MainActor.run {
                    isSaving = false
                    saveSuccess = true
                    verifyDataSaved() // 저장 확인
                    print("저장 성공")
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                    print("저장 실패: \(error)")
                }
            }
        }
    }


    private func saveSchedulesToCoreDataOnly(plan: HealthPlanResponse) async throws {
        print("Core Data 전용 저장 시작 - 스케줄 개수: \(plan.schedules.count)")

        for (index, scheduleItem) in plan.schedules.enumerated() {
            if plan.planType == "routine" {
                // 루틴의 경우: 반복 기간 동안 개별 인스턴스 생성
                try await createRoutineInstances(scheduleItem: scheduleItem, index: index)
            } else {
                // 단일/복수 일정: 기존 방식
                let newSchedule = CoreDataService.shared.create(ScheduleEntity.self)
                newSchedule.id = UUID()
                newSchedule.title = scheduleItem.activity
                newSchedule.detail = scheduleItem.notes ?? ""

                let dates = createCorrectDatesForSchedule(scheduleIndex: index, totalSchedules: plan.schedules.count)
                newSchedule.startDate = dates.startDate
                newSchedule.endDate = dates.endDate

                newSchedule.isAllDay = false
                newSchedule.isCompleted = false
                newSchedule.repeatRule = nil
                newSchedule.hasRepeatEndDate = false
                newSchedule.repeatEndDate = nil
                newSchedule.alarm = nil
                newSchedule.scheduleType = "ai_generated"
                newSchedule.createdAt = Date()
                newSchedule.updatedAt = Date()
                newSchedule.eventIdentifier = nil

                print("Core Data 저장 \(index + 1): \(newSchedule.title ?? "제목없음") - \(dates.startDate) ~ \(dates.endDate)")
            }
        }

        try CoreDataService.shared.saveContext()
        print("Core Data 저장 완료")
    }
    
    // MARK: - 루틴 개별 인스턴스 생성
    private func createRoutineInstances(scheduleItem: AIScheduleItem, index: Int) async throws {
        guard let dayString = scheduleItem.day else {
            print("⚠️ 루틴에 요일 정보가 없음")
            return
        }
        
        let calendar = Calendar.current
        let timeComponents = parseTime(from: scheduleItem.time)
        let endTimeComponents = parseEndTime(from: scheduleItem.time)
        
        // 루틴 기간 내의 모든 해당 요일 찾기
        let weekdayMapping: [String: Int] = [
            "일요일": 1, "월요일": 2, "화요일": 3, "수요일": 4,
            "목요일": 5, "금요일": 6, "토요일": 7
        ]
        
        guard let targetWeekday = weekdayMapping[dayString] else {
            print("⚠️ 알 수 없는 요일: \(dayString)")
            return
        }
        
        // 같은 루틴 시리즈에 대한 공통 seriesId 생성
        let seriesId = UUID()
        
        // 루틴 시작일부터 종료일까지 해당 요일의 모든 날짜 찾기
        var currentDate = routineStartDate
        var instanceCount = 0
        
        while currentDate <= routineEndDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            
            if weekday == targetWeekday {
                // 해당 요일에 일정 생성
                let startOfDay = calendar.startOfDay(for: currentDate)
                let startDateTime = calendar.date(byAdding: .hour, value: timeComponents.hour, to: startOfDay)!
                    .addingTimeInterval(TimeInterval(timeComponents.minute * 60))
                let endDateTime = calendar.date(byAdding: .hour, value: endTimeComponents.hour, to: startOfDay)!
                    .addingTimeInterval(TimeInterval(endTimeComponents.minute * 60))
                
                let newSchedule = CoreDataService.shared.create(ScheduleEntity.self)
                newSchedule.id = UUID()
                newSchedule.title = scheduleItem.activity
                newSchedule.detail = scheduleItem.notes ?? ""
                newSchedule.startDate = startDateTime
                newSchedule.endDate = endDateTime
                newSchedule.isAllDay = false
                newSchedule.isCompleted = false
                newSchedule.repeatRule = "매주" // 루틴임을 표시
                newSchedule.hasRepeatEndDate = true
                newSchedule.repeatEndDate = routineEndDate
                newSchedule.alarm = nil
                newSchedule.scheduleType = "ai_generated"
                newSchedule.createdAt = Date()
                newSchedule.updatedAt = Date()
                newSchedule.eventIdentifier = nil
                
                // 중요: seriesId와 occurrenceIndex 설정
                newSchedule.seriesId = seriesId
                newSchedule.occurrenceIndex = Int64(instanceCount)
                
                instanceCount += 1
                print("루틴 인스턴스 \(instanceCount) 생성: \(scheduleItem.activity) - \(startDateTime) (seriesId: \(seriesId))")
            }
            
            // 다음 날로 이동
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        print("✅ 루틴 '\(scheduleItem.activity)' 총 \(instanceCount)개 인스턴스 생성 완료 (seriesId: \(seriesId))")
    }
    

    // 저장 후 확인
    private func verifyDataSaved() {
        do {
            let schedules = try CoreDataService.shared.fetch(
                ScheduleEntity.self,
                predicate: NSPredicate(format: "scheduleType == %@", "ai_generated")
            )
            print("저장된 AI 스케줄 개수: \(schedules.count)")
            for schedule in schedules {
                print("- \(schedule.title ?? "제목없음"): \(schedule.startDate ?? Date())")
            }
        } catch {
            print("저장 확인 실패: \(error)")
        }
    }
}
