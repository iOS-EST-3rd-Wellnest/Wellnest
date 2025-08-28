//
//  HealthPlanAI.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import Foundation
import Combine

extension AlanAIService {
    func generateHealthPlan(_ request: PlanRequest, userProfile: UserProfile = .default) {
        healthPlan = nil

        guard !clientID.isEmpty else {
            let calendar = Calendar.current
            let today = Date()
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let todayString = dateFormatter.string(from: today)
            let tomorrowString = dateFormatter.string(from: tomorrow)

            let weekdayNames = ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]

            var testSchedules: [AIScheduleItem] = []

            if request.planType == .routine {

                let selectedWeekdayNames = Array(request.selectedWeekdays).sorted().map { index in
                    let weekdayName = weekdayNames[index]
                    return weekdayName
                }

                for (index, weekdayName) in selectedWeekdayNames.enumerated() {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    
                    let startTime = request.routineStartTime ?? Date()
                    let endTime = request.routineEndTime ?? Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
                    
                    let startTimeString = timeFormatter.string(from: startTime)
                    let endTimeString = timeFormatter.string(from: endTime)
                    let timeString = "\(startTimeString)-\(endTimeString)"

                    let activity = generateActivityFromPreferences(request.preferences, index: index)
                    let notes = generateNotesForActivity(activity, weekday: weekdayName)

                    testSchedules.append(
                        AIScheduleItem(
                            day: weekdayName,
                            date: nil,
                            time: timeString,
                            activity: activity,
                            notes: notes
                        )
                    )
                }

                if testSchedules.isEmpty {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    
                    let startTime = request.routineStartTime ?? Date()
                    let endTime = request.routineEndTime ?? Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
                    
                    let startTimeString = timeFormatter.string(from: startTime)
                    let endTimeString = timeFormatter.string(from: endTime)
                    let timeString = "\(startTimeString)-\(endTimeString)"
                    
                    let activity = generateActivityFromPreferences(request.preferences, index: 0)
                    let notes = generateNotesForActivity(activity, weekday: "월요일")
                    
                    testSchedules.append(
                        AIScheduleItem(
                            day: "월요일",
                            date: nil,
                            time: timeString,
                            activity: activity,
                            notes: notes
                        )
                    )
                }
            } else if request.planType == .single {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                
                let startTime = request.singleStartTime ?? Date()
                let endTime = request.singleEndTime ?? Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
                
                let startTimeString = timeFormatter.string(from: startTime)
                let endTimeString = timeFormatter.string(from: endTime)
                let timeString = "\(startTimeString)-\(endTimeString)"
                
                let activity = generateActivityFromPreferences(request.preferences, index: 0)
                let notes = generateNotesForActivity(activity, weekday: nil)
                
                testSchedules = [
                    AIScheduleItem(
                        day: nil,
                        date: todayString,
                        time: timeString,
                        activity: activity,
                        notes: notes
                    )
                ]
            } else {
                testSchedules = generateMultipleSchedules(request: request, todayString: todayString, tomorrowString: tomorrowString)
            }

            let testPlan = HealthPlanResponse(
                planType: request.planType.rawValue,
                title: "테스트 \(request.planType.displayName) 플랜",
                description: "Client ID가 없을 때 표시되는 테스트 플랜입니다. API 연결 후 실제 플랜이 생성됩니다.",
                schedules: testSchedules
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isLoading = false
                self.healthPlan = testPlan

                print("플랜 생성 성공")
            }
            return
        }

        let prompt = AlanPromptBuilder.buildPrompt(from: request, userProfile: userProfile)

        let healthPlanExtractor: (String) -> String? = { [weak self] response in
            if let data = response.data(using: .utf8),
               let outerJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = outerJson["content"] as? String {

                if let json = self?.extractJSONFromCodeBlock(content),
                   json.contains("plan_type") {
                    return json
                }

                if let json = self?.extractJSONByBraces(content),
                   json.contains("plan_type") {
                    return json
                }
            }

            if let json = self?.extractJSONByBraces(response),
               json.contains("plan_type") && json.contains("schedules") {
                return json
            }

            if let json = self?.extractJSONFromCodeBlock(response),
               json.contains("plan_type") {
                return json
            }

            if let json = self?.extractJSONByKeyword(response, keyword: "plan_type") {
                return json
            }

            return nil
        }

        self.request(prompt: prompt, responseType: HealthPlanResponse.self, jsonExtractor: healthPlanExtractor) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let healthPlan):
                    print("플랜 생성 성공")
                    // 날짜 범위 검증 및 필터링
                    let validatedPlan = self?.validateAndFilterSchedules(healthPlan, request: request) ?? healthPlan
                    self?.healthPlan = validatedPlan
                case .failure(let error):
                    print("플랜 생성 실패")
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func generateMultipleSchedules(request: PlanRequest, todayString: String, tomorrowString: String) -> [AIScheduleItem] {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startDate = request.multipleStartDate ?? Date()
        let endDate = request.multipleEndDate ?? Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        let startTime = request.multipleStartTime ?? Date()
        let endTime = request.multipleEndTime ?? Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime

        let calendar = Calendar.current
        var schedules: [AIScheduleItem] = []
        
        // 시작일과 종료일이 같은 날인지 확인
        let isSameDay = calendar.isDate(startDate, inSameDayAs: endDate)
        
        if isSameDay {
            // 같은 날: 시간 범위 내에서 여러 운동 일정 생성
            let totalMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
            let scheduleCount = max(1, min(request.preferences.count, 5)) // 최대 5개
            let minutesPerSchedule = max(30, totalMinutes / scheduleCount)
            
            for index in 0..<scheduleCount {
                let timeOffset = minutesPerSchedule * index
                let adjustedStartTime = calendar.date(byAdding: .minute, value: timeOffset, to: startTime) ?? startTime
                let adjustedEndTime = calendar.date(byAdding: .minute, value: minutesPerSchedule, to: adjustedStartTime) ?? adjustedStartTime
                
                if adjustedStartTime >= endTime { break }
                
                let finalEndTime = min(adjustedEndTime, endTime)
                
                let startTimeString = timeFormatter.string(from: adjustedStartTime)
                let endTimeString = timeFormatter.string(from: finalEndTime)
                let timeString = "\(startTimeString)-\(endTimeString)"
                
                let activity = generateActivityFromPreferences(request.preferences, index: index)
                let notes = generateNotesForActivity(activity, weekday: nil)
                
                let currentDateString = dateFormatter.string(from: startDate)
                
                schedules.append(
                    AIScheduleItem(
                        day: nil,
                        date: currentDateString,
                        time: timeString,
                        activity: activity,
                        notes: notes
                    )
                )
            }
        } else {
            // 다른 날: 날짜 범위 내에서 각 날마다 하나씩 생성
            let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            let maxSchedules = min(daysBetween + 1, 7) // 최대 7개 일정
            
            for dayIndex in 0..<maxSchedules {
                guard let currentDate = calendar.date(byAdding: .day, value: dayIndex, to: startDate) else { continue }
                
                if currentDate > endDate { break }
                
                let activity = generateActivityFromPreferences(request.preferences, index: dayIndex)
                let notes = generateNotesForActivity(activity, weekday: nil)
                
                let startTimeString = timeFormatter.string(from: startTime)
                let endTimeString = timeFormatter.string(from: endTime)
                let timeString = "\(startTimeString)-\(endTimeString)"
                
                let currentDateString = dateFormatter.string(from: currentDate)
                
                schedules.append(
                    AIScheduleItem(
                        day: nil,
                        date: currentDateString,
                        time: timeString,
                        activity: activity,
                        notes: notes
                    )
                )
            }
        }
        
        return schedules
    }

    private func generateActivityFromPreferences(_ preferences: [String], index: Int) -> String {
        guard !preferences.isEmpty else {
            return "테스트 - 기본 운동"
        }

        let selectedCategory = preferences[index % preferences.count]
        
        return "테스트 - \(selectedCategory)"
    }
    
    private func generateNotesForActivity(_ activity: String, weekday: String?) -> String {
        if let weekday = weekday {
            return "\(weekday) \(activity) 일정입니다."
        } else {
            return "테스트용 일정입니다. 실제 API 연결 후 개인맞춤 운동이 생성됩니다."
        }
    }
    
    private func validateAndFilterSchedules(_ healthPlan: HealthPlanResponse, request: PlanRequest) -> HealthPlanResponse {
        // Multiple 플랜이 아니면 검증하지 않음
        guard request.planType == .multiple else {
            return healthPlan
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startDate = request.multipleStartDate ?? Date()
        let endDate = request.multipleEndDate ?? Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        let calendar = Calendar.current
        
        print("날짜 검증 시작 - 허용 범위: \(dateFormatter.string(from: startDate)) ~ \(dateFormatter.string(from: endDate))")
        
        // 날짜 범위 내의 스케줄만 필터링
        let validSchedules = healthPlan.schedules.filter { scheduleItem in
            guard let dateString = scheduleItem.date,
                  let scheduleDate = dateFormatter.date(from: dateString) else {
                print("날짜 파싱 실패: \(scheduleItem.date ?? "nil")")
                return false
            }
            
            // 날짜만 비교 (시간 무시)
            let calendar = Calendar.current
            let scheduleDay = calendar.startOfDay(for: scheduleDate)
            let startDay = calendar.startOfDay(for: startDate)
            let endDay = calendar.startOfDay(for: endDate)
            let isValid = scheduleDay >= startDay && scheduleDay <= endDay
            if !isValid {
                print("범위 벗어남: \(dateString) (허용: \(dateFormatter.string(from: startDate)) ~ \(dateFormatter.string(from: endDate)))")
            }
            return isValid
        }
        
        print("원본 스케줄: \(healthPlan.schedules.count)개, 필터링 후: \(validSchedules.count)개")
        
        // 같은 날짜인 경우 카테고리별 일정 생성 보장
        let isSameDay = calendar.isDate(startDate, inSameDayAs: endDate)
        if isSameDay {
            // AI가 제대로 된 카테고리별 일정을 생성했는지 확인
            let expectedCount = request.preferences.count
            if validSchedules.count < expectedCount {
                print("AI 응답 부족: \(validSchedules.count)개 < 예상 \(expectedCount)개. 강제 생성 시작")
                let adjustedSchedules = generateSchedulesForCategories(validSchedules, request: request)
                return HealthPlanResponse(
                    planType: healthPlan.planType,
                    title: healthPlan.title,
                    description: healthPlan.description,
                    schedules: adjustedSchedules
                )
            } else {
                let adjustedSchedules = adjustSchedulesForSameDay(validSchedules, request: request)
                return HealthPlanResponse(
                    planType: healthPlan.planType,
                    title: healthPlan.title,
                    description: healthPlan.description,
                    schedules: adjustedSchedules
                )
            }
        }
        
        return HealthPlanResponse(
            planType: healthPlan.planType,
            title: healthPlan.title,
            description: healthPlan.description,
            schedules: validSchedules
        )
    }
    
    private func adjustSchedulesForSameDay(_ schedules: [AIScheduleItem], request: PlanRequest) -> [AIScheduleItem] {
        guard let startTime = request.multipleStartTime,
              let endTime = request.multipleEndTime,
              let startDate = request.multipleStartDate else {
            return schedules
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let calendar = Calendar.current
        let totalMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        let scheduleCount = schedules.count
        let minutesPerSchedule = max(30, totalMinutes / scheduleCount)
        
        let targetDateString = dateFormatter.string(from: startDate)
        
        return schedules.enumerated().map { index, schedule in
            let timeOffset = minutesPerSchedule * index
            let adjustedStartTime = calendar.date(byAdding: .minute, value: timeOffset, to: startTime) ?? startTime
            let adjustedEndTime = calendar.date(byAdding: .minute, value: minutesPerSchedule, to: adjustedStartTime) ?? adjustedStartTime
            
            let finalEndTime = min(adjustedEndTime, endTime)
            
            let startTimeString = timeFormatter.string(from: adjustedStartTime)
            let endTimeString = timeFormatter.string(from: finalEndTime)
            let timeString = "\(startTimeString)-\(endTimeString)"
            
            return AIScheduleItem(
                day: nil,
                date: targetDateString,
                time: timeString,
                activity: schedule.activity,
                notes: schedule.notes
            )
        }
    }
    
    private func generateSchedulesForCategories(_ existingSchedules: [AIScheduleItem], request: PlanRequest) -> [AIScheduleItem] {
        guard let startTime = request.multipleStartTime,
              let endTime = request.multipleEndTime,
              let startDate = request.multipleStartDate else {
            return existingSchedules
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let calendar = Calendar.current
        let totalMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        let categoryCount = request.preferences.count
        let minutesPerSchedule = max(30, totalMinutes / categoryCount)
        
        let targetDateString = dateFormatter.string(from: startDate)
        var newSchedules: [AIScheduleItem] = []
        
        // 각 선택된 카테고리마다 일정 생성
        for (index, category) in request.preferences.enumerated() {
            let timeOffset = minutesPerSchedule * index
            let adjustedStartTime = calendar.date(byAdding: .minute, value: timeOffset, to: startTime) ?? startTime
            let adjustedEndTime = calendar.date(byAdding: .minute, value: minutesPerSchedule, to: adjustedStartTime) ?? adjustedStartTime
            
            let finalEndTime = min(adjustedEndTime, endTime)
            
            let startTimeString = timeFormatter.string(from: adjustedStartTime)
            let endTimeString = timeFormatter.string(from: finalEndTime)
            let timeString = "\(startTimeString)-\(endTimeString)"
            
            // 기존 스케줄 중에서 해당 카테고리와 매칭되는 활동이 있는지 확인
            let activity = existingSchedules.first { schedule in
                schedule.activity.contains(category) || category.contains(schedule.activity)
            }?.activity ?? "\(category) 운동"
            
            let notes = existingSchedules.first { schedule in
                schedule.activity.contains(category) || category.contains(schedule.activity)
            }?.notes ?? "\(category) 활동을 통해 건강한 하루를 시작하세요."
            
            newSchedules.append(
                AIScheduleItem(
                    day: nil,
                    date: targetDateString,
                    time: timeString,
                    activity: activity,
                    notes: notes
                )
            )
        }
        
        print("카테고리별 강제 생성: \(newSchedules.count)개 일정 완료")
        return newSchedules
    }
}
