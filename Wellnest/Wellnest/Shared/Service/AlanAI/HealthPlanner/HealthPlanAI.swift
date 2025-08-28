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

            // 요일 매핑 (UI에서 사용하는 인덱스 체계에 맞춰 조정)
            // UI에서 월요일=0, 화요일=1, ... 일요일=6 이라면:
            let weekdayNames = ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]

            // 또는 UI에서 일요일=0, 월요일=1, ... 토요일=6 이라면 기존 배열 유지:
            //             let weekdayNames = ["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"]

            var testSchedules: [AIScheduleItem] = []

            if request.planType == .routine {
                print("🔍 루틴 타입 - selectedWeekdays: \(request.selectedWeekdays)")

                // 선택된 요일들로 스케줄 생성
                let selectedWeekdayNames = Array(request.selectedWeekdays).sorted().map { index in
                    let weekdayName = weekdayNames[index]
                    print("🔍 인덱스 \(index) -> \(weekdayName)")
                    return weekdayName
                }

                for (index, weekdayName) in selectedWeekdayNames.enumerated() {
                    // 사용자가 입력한 루틴 시간 사용
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    
                    let startTime = request.routineStartTime ?? Date()
                    let endTime = request.routineEndTime ?? Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
                    
                    let startTimeString = timeFormatter.string(from: startTime)
                    let endTimeString = timeFormatter.string(from: endTime)
                    let timeString = "\(startTimeString)-\(endTimeString)"
                    
                    // 선택한 카테고리에 따른 운동 생성
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

                // 요일이 선택되지 않은 경우 기본값
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
                // 단일 일정의 경우
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
                // 여러 일정의 경우: 선택한 카테고리 개수만큼 일정 생성
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

                print("==================================")
                print(self.healthPlan)
                print("==================================")

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
    
    // MARK: - 여러 일정 생성 헬퍼 함수
    private func generateMultipleSchedules(request: PlanRequest, todayString: String, tomorrowString: String) -> [AIScheduleItem] {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // 사용자가 선택한 날짜를 사용 (없으면 오늘)
        let selectedDate = request.multipleStartDate ?? Date()
        let startTime = request.multipleStartTime ?? Date()
        let endTime = request.multipleEndTime ?? Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
        
        // 선택한 카테고리 개수만큼 일정 생성
        let scheduleCount = max(1, request.preferences.count)
        var schedules: [AIScheduleItem] = []
        
        let calendar = Calendar.current
        
        // 하루 안에서 시간 분배
        let totalMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        
        // 각 일정의 길이 계산 (전체 시간을 일정 개수로 나눔)
        let minutesPerSchedule = max(30, totalMinutes / scheduleCount) // 최소 30분
        
        for index in 0..<scheduleCount {
            // 시작 시간 계산 (이전 일정들의 시간만큼 offset)
            let timeOffset = minutesPerSchedule * index
            let adjustedStartTime = calendar.date(byAdding: .minute, value: timeOffset, to: startTime) ?? startTime
            
            // 종료 시간 계산
            let adjustedEndTime = calendar.date(byAdding: .minute, value: minutesPerSchedule, to: adjustedStartTime) ?? adjustedStartTime
            
            // 시간이 설정한 종료 시간을 넘어가면 중단
            if adjustedStartTime >= endTime {
                break
            }
            
            // 종료 시간이 설정한 종료 시간을 넘어가면 조정
            let finalEndTime = min(adjustedEndTime, endTime)
            
            // 사용자가 선택한 날짜를 기준으로 시간만 추출
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
            
            // 사용자가 선택한 날짜를 문자열로 변환
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
    
    // MARK: - 카테고리별 운동 생성 헬퍼 함수들
    private func generateActivityFromPreferences(_ preferences: [String], index: Int) -> String {
        guard !preferences.isEmpty else {
            return "테스트 - 기본 운동"
        }
        
        // 여러 카테고리가 선택된 경우 인덱스에 따라 순환
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
