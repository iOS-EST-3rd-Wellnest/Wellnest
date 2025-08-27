//
//  PlanRequest.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation

struct PlanRequest {
    let planType: PlanType
    let userGoal: String
    let timeframe: String?
    let preferences: [String]

    func toPrompt(userProfile: UserProfile) -> String {
        // Core Data에서 최신 사용자 정보 가져오기
        let userInfo = fetchLatestUserInfo()

        let basePrompt = """
        당신은 전문 건강 및 피트니스 플래너 AI입니다. 

        사용자 프로필:
        - 성별: \(userInfo?.gender ?? "미지정")
        - 나이: \(userInfo?.ageRange ?? "미지정")
        - 키: \(formatHeight(userInfo?.height))
        - 몸무게: \(formatWeight(userInfo?.weight))

        사용자 요청:
        - 계획 유형: \(planType.displayName)
        - 목표: \(userGoal)
        - 일정: \(timeframe ?? "미지정")
        - 선호 운동: \(preferences.joined(separator: ", "))

        중요: 반드시 아래 JSON 형식으로만 응답해주세요. 다른 텍스트는 포함하지 마세요.

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
          ]
        }

        위 JSON 형식을 정확히 따라 응답해주세요.
        """

        return basePrompt
    }

    private func fetchLatestUserInfo() -> UserEntity? {
        do {
            let sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            let entities = try CoreDataService.shared.fetch(
                UserEntity.self,
                predicate: nil,
                sortDescriptors: sortDescriptors
            )
            return entities.first
        } catch {
            print("사용자 정보 조회 실패: \(error)")
            return nil
        }
    }

    private func formatHeight(_ height: Any?) -> String {
        guard let height = height else { return "미지정" }

        if let intHeight = height as? Int, intHeight > 0 {
            return "\(intHeight)cm"
        } else if let doubleHeight = height as? Double, doubleHeight > 0 {
            return "\(Int(doubleHeight))cm"
        }
        return "미지정"
    }

    private func formatWeight(_ weight: Any?) -> String {
        guard let weight = weight else { return "미지정" }

        if let intWeight = weight as? Int, intWeight > 0 {
            return "\(intWeight)kg"
        } else if let doubleWeight = weight as? Double, doubleWeight > 0 {
            return "\(Int(doubleWeight))kg"
        }
        return "미지정"
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
