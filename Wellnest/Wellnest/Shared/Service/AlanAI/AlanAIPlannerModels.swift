//
//  AlanAIPlannerModels.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation

// MARK: - Plan Types
enum PlanType: String, CaseIterable {
    case single = "single"      // 단일 일정
    case multiple = "multiple"  // 여러 일정
    case routine = "routine"    // 루틴

    var displayName: String {
        switch self {
        case .single: return "단일 일정"
        case .multiple: return "여러 일정"
        case .routine: return "루틴"
        }
    }
}

// MARK: - Health Plan Response Models
struct HealthPlanResponse: Codable, Identifiable {
    let id = UUID()
    let planType: String
    let title: String
    let description: String?
    let schedules: [AIScheduleItem]
    let resources: ResourceInfo?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case title, description, schedules, resources
    }
}

struct AIScheduleItem: Codable, Identifiable {
    let id = UUID()
    let day: String?           // 요일 (루틴용)
    let date: String?          // 날짜 (일정용)
    let time: String
    let activity: String
    let duration: String
    let intensity: String?
    let location: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case day, date, time, activity, duration, intensity, location, notes
    }
}

struct ResourceInfo: Codable {
    let equipment: [String]?
    let videos: [VideoResource]?
    let locations: [LocationResource]?
    let products: [ProductResource]?
}

struct VideoResource: Codable, Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let thumbnail: String?
    let duration: String?

    enum CodingKeys: String, CodingKey {
        case title, url, thumbnail, duration
    }
}

struct LocationResource: Codable, Identifiable {
    let id = UUID()
    let name: String
    let address: String?
    let type: String // gym, park, pool 등
    let rating: Double?

    enum CodingKeys: String, CodingKey {
        case name, address, type, rating
    }
}

struct ProductResource: Codable, Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let price: String?
    let link: String?

    enum CodingKeys: String, CodingKey {
        case name, category, price, link
    }
}

// MARK: - Plan Request Model
struct PlanRequest {
    let planType: PlanType
    let userGoal: String
    let timeframe: String?
    let preferences: [String]
    let intensity: String

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
        - 운동 강도: \(intensity)

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

// MARK: - User Profile Model
struct UserProfile {
    let gender: String
    let age: Int
    let height: Int
    let weight: Int
    let sleepSchedule: String
    let exerciseTimeSlot: String
    let preferredExercises: [String]
    let exerciseIntensity: String

    static let `default` = UserProfile(
        gender: "남성",
        age: 25,
        height: 180,
        weight: 90,
        sleepSchedule: "오전 12시 ~ 오전 7시 (7시간)",
        exerciseTimeSlot: "오후 8시 ~ 오후 11시",
        preferredExercises: ["유산소", "근력운동", "요가", "필라테스", "수영", "사이클링"],
        exerciseIntensity: "보통"
    )
}
