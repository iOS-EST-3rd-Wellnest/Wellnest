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
                    let baseHour = 9 + (index * 2) // 9시, 11시, 13시, 15시 등으로 분산
                    let timeString = String(format: "%02d:00-%02d:00", baseHour, baseHour + 1)

                    testSchedules.append(
                        AIScheduleItem(
                            day: weekdayName,
                            date: nil,
                            time: timeString,
                            activity: "테스트 운동 \(index + 1) - \(request.preferences.first ?? "기본 운동")",
                            notes: "\(weekdayName) 테스트용 운동입니다."
                        )
                    )
                }

                // 요일이 선택되지 않은 경우 기본값
                if testSchedules.isEmpty {
                    testSchedules.append(
                        AIScheduleItem(
                            day: "월요일",
                            date: nil,
                            time: "09:00-10:00",
                            activity: "테스트 운동 - \(request.preferences.first ?? "기본 운동")",
                            notes: "기본 테스트용 운동입니다."
                        )
                    )
                }
            } else {
                // single, multiple 타입의 경우 기존 로직
                testSchedules = [
                    AIScheduleItem(
                        day: nil,
                        date: todayString,
                        time: "09:00-10:00",
                        activity: "테스트 운동 - \(request.preferences.first ?? "기본 운동")",
                        notes: "테스트용 운동입니다. 실제 API 연결 후 개인맞춤 운동이 생성됩니다."
                    )
                ]
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
}
