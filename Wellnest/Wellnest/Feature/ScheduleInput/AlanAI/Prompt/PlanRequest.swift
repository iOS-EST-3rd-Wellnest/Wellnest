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
    let selectedWeekdays: Set<Int>

    let routineStartTime: Date?
    let routineEndTime: Date?
    let singleStartTime: Date?
    let singleEndTime: Date?
    let multipleStartTime: Date?
    let multipleEndTime: Date?
    let multipleStartDate: Date?
    let multipleEndDate: Date?

    func toPrompt(userProfile: UserProfile) -> String {
        let userInfo = fetchLatestUserInfo()

        let basePrompt = """
        당신은 전문 건강 및 피트니스 플래너 AI입니다. 

        사용자 프로필:
        - 성별: \(userInfo?.gender ?? "미지정")
        - 나이: \(userInfo?.ageRange ?? "미지정")
        - 키: \(formatHeight(userInfo?.height))
        - 몸무게: \(formatWeight(userInfo?.weight))
        - 웰니스 목표: \(userInfo?.goal ?? "미지정")
        - 선호 활동 시간대: \(userInfo?.preferredTimeSlot ?? "미지정")
        - 선호 날씨: \(userInfo?.weatherPreferences ?? "미지정")
        - 현재 건강 상태: \(userInfo?.healthConditions ?? "미지정")

        사용자 요청:
        - 계획 유형: \(planType.displayName)
        - 목표: \(userGoal)
        - 일정: \(timeframe ?? "미지정")
        - 선호 운동: \(preferences.joined(separator: ", "))
        \(planType == .routine ? "- 선택된 요일: \(getSelectedWeekdayNames())" : "")

        \(getInstructionsByPlanType())

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

    private func getSelectedWeekdayNames() -> String {
        let weekdayNames = ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]
        let selectedNames = Array(selectedWeekdays).sorted().map { weekdayNames[$0] }
        return selectedNames.joined(separator: ", ")
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "미지정" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func getInstructionsByPlanType() -> String {
        switch planType {
        case .routine:
            return """
            
            일정 생성 지침:
            - 선택된 요일(\(getSelectedWeekdayNames()))에 맞춰 루틴 일정을 생성해주세요
            - 각 요일마다 다양한 운동을 배치하여 균형잡힌 운동 계획을 세워주세요
            - 사용자의 선호 활동 시간대를 고려하여 적절한 시간을 설정해주세요
            - 사용자의 건강 상태와 웰니스 목표에 맞는 운동 강도를 조절해주세요
            """
        case .single:
            return """
            
            일정 생성 지침:
            - 지정된 날짜와 시간에 맞는 단일 운동 일정을 생성해주세요
            - 사용자의 선호 운동과 목표에 적합한 활동을 추천해주세요
            - 현재 날씨와 사용자의 날씨 선호도를 고려해주세요
            """
        case .multiple:
            let startDateString = formatDate(multipleStartDate)
            let endDateString = formatDate(multipleEndDate)
            let selectedCategories = preferences.joined(separator: ", ")
            return """
            
            일정 생성 지침:
            - 선택된 카테고리: \(selectedCategories)
            - 각 카테고리마다 별도 일정 생성 (총 \(preferences.count)개)
            - 날짜 범위: \(startDateString) ~ \(endDateString)
            - 시간을 나누어 각 카테고리에 배정
            """
        }
    }
}
