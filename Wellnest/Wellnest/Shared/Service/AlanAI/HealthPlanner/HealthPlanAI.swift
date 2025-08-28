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
                    self?.healthPlan = healthPlan
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

        let selectedDate = request.multipleStartDate ?? Date()
        let startTime = request.multipleStartTime ?? Date()
        let endTime = request.multipleEndTime ?? Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime

        let scheduleCount = max(1, request.preferences.count)
        var schedules: [AIScheduleItem] = []
        
        let calendar = Calendar.current

        let totalMinutes = Int(endTime.timeIntervalSince(startTime) / 60)

        let minutesPerSchedule = max(30, totalMinutes / scheduleCount)
        
        for index in 0..<scheduleCount {
            let timeOffset = minutesPerSchedule * index
            let adjustedStartTime = calendar.date(byAdding: .minute, value: timeOffset, to: startTime) ?? startTime

            let adjustedEndTime = calendar.date(byAdding: .minute, value: minutesPerSchedule, to: adjustedStartTime) ?? adjustedStartTime

            if adjustedStartTime >= endTime {
                break
            }

            let finalEndTime = min(adjustedEndTime, endTime)

            let baseDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            let startTimeComponents = calendar.dateComponents([.hour, .minute], from: adjustedStartTime)
            let endTimeComponents = calendar.dateComponents([.hour, .minute], from: finalEndTime)
            
            var fixedStartComponents = baseDateComponents
            fixedStartComponents.hour = startTimeComponents.hour
            fixedStartComponents.minute = startTimeComponents.minute
            
            var fixedEndComponents = baseDateComponents
            fixedEndComponents.hour = endTimeComponents.hour
            fixedEndComponents.minute = endTimeComponents.minute
            
            let fixedStartTime = calendar.date(from: fixedStartComponents) ?? adjustedStartTime
            let fixedEndTime = calendar.date(from: fixedEndComponents) ?? finalEndTime
            
            let startTimeString = timeFormatter.string(from: fixedStartTime)
            let endTimeString = timeFormatter.string(from: fixedEndTime)
            let timeString = "\(startTimeString)-\(endTimeString)"
            
            let activity = generateActivityFromPreferences(request.preferences, index: index)
            let notes = generateNotesForActivity(activity, weekday: nil)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let selectedDateString = dateFormatter.string(from: selectedDate)
            
            schedules.append(
                AIScheduleItem(
                    day: nil,
                    date: selectedDateString,
                    time: timeString,
                    activity: activity,
                    notes: notes
                )
            )
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
}
