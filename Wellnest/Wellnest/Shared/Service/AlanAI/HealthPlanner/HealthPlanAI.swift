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
        print("🚀 generateHealthPlan 시작")
        healthPlan = nil  // 먼저 초기화

        guard !clientID.isEmpty else {
            print("⚠️ Client ID가 없어 테스트 데이터를 생성합니다.")

            // ⭐️ 오늘 날짜를 기준으로 테스트 데이터 생성
            let calendar = Calendar.current
            let today = Date()
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let todayString = dateFormatter.string(from: today)
            let tomorrowString = dateFormatter.string(from: tomorrow)

            // 테스트용 더미 데이터를 오늘 날짜로 생성
            let testPlan = HealthPlanResponse(
                planType: request.planType.rawValue,
                title: "🧪 테스트 \(request.planType.displayName) 플랜",
                description: "Client ID가 없을 때 표시되는 테스트 플랜입니다. API 연결 후 실제 플랜이 생성됩니다.",
                schedules: [
                    AIScheduleItem(
                        day: request.planType == .routine ? "월요일" : nil,
                        date: request.planType != .routine ? todayString : nil, // 오늘 날짜
                        time: "09:00-10:00",
                        activity: "테스트 운동 - \(request.preferences.first ?? "기본 운동")",
                        notes: "테스트용 운동입니다. 실제 API 연결 후 개인맞춤 운동이 생성됩니다."
                    ),
                    AIScheduleItem(
                        day: request.planType == .routine ? "수요일" : nil,
                        date: request.planType != .routine ? tomorrowString : nil, // 내일 날짜
                        time: "14:00-15:00",
                        activity: "테스트 운동 2 - 유산소",
                        notes: "심폐지구력 향상을 위한 운동입니다."
                    )
                ]
            )

            print("📋 테스트 데이터 생성: \(testPlan.title)")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isLoading = false
                self.healthPlan = testPlan
                print("✅ 테스트 데이터 설정 완료 - healthPlan: \(self.healthPlan?.title ?? "nil")")
            }
            return
        }

        let prompt = AlanPromptBuilder.buildPrompt(from: request, userProfile: userProfile)
        print("📝 생성된 프롬프트 길이: \(prompt.count)")

        // 헬스플래너 전용 JSON 추출기
        let healthPlanExtractor: (String) -> String? = { [weak self] response in
            print("🔍 JSON 추출 시작, 응답 길이: \(response.count)")

            // 1. content 필드에서 JSON 추출 시도 (우선순위 높음)
            if let data = response.data(using: .utf8),
               let outerJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = outerJson["content"] as? String {
                print("🔍 content 필드 발견, content 내부에서 JSON 추출 시도")

                // content 내의 코드 블록에서 JSON 추출
                if let json = self?.extractJSONFromCodeBlock(content),
                   json.contains("plan_type") {
                    print("✅ Content의 CodeBlock에서 JSON 추출 성공")
                    return json
                }

                // content 내의 중괄호에서 JSON 추출
                if let json = self?.extractJSONByBraces(content),
                   json.contains("plan_type") {
                    print("✅ Content의 Braces에서 JSON 추출 성공")
                    return json
                }

                print("❌ Content 내부에서 plan_type을 포함한 JSON을 찾을 수 없음")
            }

            // 2. 전체 응답에서 plan_type이 포함된 JSON 확인
            if let json = self?.extractJSONByBraces(response),
               json.contains("plan_type") && json.contains("schedules") {
                print("✅ 전체 응답 Braces 방식으로 JSON 추출 성공")
                return json
            }

            // 3. 기존 방식들로 시도
            if let json = self?.extractJSONFromCodeBlock(response),
               json.contains("plan_type") {
                print("✅ 전체 응답 CodeBlock 방식으로 JSON 추출 성공")
                return json
            }
            if let json = self?.extractJSONByKeyword(response, keyword: "plan_type") {
                print("✅ Keyword 방식으로 JSON 추출 성공")
                return json
            }

            print("❌ 모든 JSON 추출 방식 실패")
            print("🔍 응답 내용 일부: \(String(response.prefix(200)))")
            return nil
        }

        self.request(prompt: prompt, responseType: HealthPlanResponse.self, jsonExtractor: healthPlanExtractor) { [weak self] result in
            print("📊 AI 응답 처리 시작")
            DispatchQueue.main.async {
                switch result {
                case .success(let healthPlan):
                    print("✅ 헬스플랜 생성 성공: \(healthPlan.title)")
                    self?.healthPlan = healthPlan
                case .failure(let error):
                    print("❌ 헬스플랜 생성 실패: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
