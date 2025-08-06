//
//  PlanRequest.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation

// MARK: - Plan Request Model
struct PlanRequest {
    let planType: PlanType
    let userGoal: String
    let timeframe: String?
    let preferences: [String]

    func toPrompt(userProfile: UserProfile) -> String {
        let basePrompt = """
        당신은 전문 건강 및 피트니스 플래너 AI입니다. 

        사용자 프로필:
        - 성별: \(userProfile.gender)
        - 나이: \(userProfile.age)세
        - 키: \(userProfile.height)cm
        - 몸무게: \(userProfile.weight)kg
        - 수면시간: \(userProfile.sleepSchedule)
        - 운동 가능시간: \(userProfile.exerciseTimeSlot)
        - 선호 운동: \(userProfile.preferredExercises.joined(separator: ", "))
        
        사용자 요청:
        - 계획 유형: \(planType.displayName)
        - 목표: \(userGoal)
        - 일정: \(timeframe ?? "미지정")
        - 선호 운동: \(preferences.joined(separator: ", "))

        **중요: 반드시 아래 JSON 형식으로만 응답해주세요. 다른 텍스트는 포함하지 마세요.**

        {
          "plan_type": "\(planType.rawValue)",
          "title": "맞춤 건강 계획 제목",
          "description": "계획에 대한 간단한 설명",
          "schedules": [
            {
              \(getScheduleFormat())
              "time": "20:00-21:00",
              "activity": "구체적인 운동명",
              "duration": "60분",
              "intensity": "중간",
              "location": "운동 장소",
              "notes": "주의사항이나 팁"
            }
          ],
          "resources": {
            "equipment": ["필요한 운동기구1", "필요한 운동기구2"],
            "videos": [
              {
                "title": "운동 가이드 영상 제목",
                "url": "https://youtube.com/watch?v=example",
                "thumbnail": "https://img.youtube.com/vi/example/0.jpg",
                "duration": "10분"
              }
            ],
            "locations": [
              {
                "name": "추천 운동 장소",
                "address": "주소",
                "type": "gym",
                "rating": 4.5
              }
            ],
            "products": [
              {
                "name": "추천 상품명",
                "category": "카테고리",
                "price": "가격",
                "link": "https://example.com/product"
              }
            ]
          }
        }

        위 JSON 형식을 정확히 따라 응답해주세요.
        """

        return basePrompt
    }

    private func getScheduleFormat() -> String {
        switch planType {
        case .routine:
            return "\"day\": \"월요일\","
        case .single, .multiple:
            return "\"date\": \"2025-08-01\","
        }
    }
}
