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

            let testPlan = HealthPlanResponse(
                planType: request.planType.rawValue,
                title: "테스트 \(request.planType.displayName) 플랜",
                description: "Client ID가 없을 때 표시되는 테스트 플랜입니다. API 연결 후 실제 플랜이 생성됩니다.",
                schedules: [
                    AIScheduleItem(
                        day: request.planType == .routine ? "월요일" : nil,
                        date: request.planType != .routine ? todayString : nil,
                        time: "09:00-10:00",
                        activity: "테스트 운동 - \(request.preferences.first ?? "기본 운동")",
                        notes: "테스트용 운동입니다. 실제 API 연결 후 개인맞춤 운동이 생성됩니다."
                    ),
                    AIScheduleItem(
                        day: request.planType == .routine ? "수요일" : nil,
                        date: request.planType != .routine ? tomorrowString : nil,
                        time: "14:00-15:00",
                        activity: "테스트 운동 2 - 유산소",
                        notes: "심폐지구력 향상을 위한 운동입니다."
                    )
                ]
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
}
