//
//  RecommendModel.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/6/25.
//

import Foundation
import SwiftUI

enum RecommendCategory: String {
    case hashtag = "hashtag"
    case goal = "goal"
    case quoteOfTheDay = "quoteOfTheDay"
    case weather = "weather"
    case video = "video"
}

struct Response: Codable {
    let content: String
}

struct ResponseStringModel: Codable {
    let category: String
    let content: String
}

struct ResponseArrayModel: Codable {
    let category: String
    let contents: [String]
}

struct WeatherRecommendModel: Codable {
    let category: String
    let description: String
    let schedules: [String]
}

struct VideoRecommendModel: Identifiable, Codable {
    let id: String
    let title: String
    let thumbnail: String
}

// MARK: - 테스트 데이터
extension ResponseStringModel {
    static let quoteOfTheDay = ResponseStringModel(category: "quoteOfTheDay", content: "꾸준한 노력은 건강한 삶으로 가는 지름길입니다.")
}

extension ResponseArrayModel {
    static let hashtag: ResponseArrayModel = ResponseArrayModel(category: "hashtag", contents: ["#건강한 식습관", "#스트레스 관리"])
    static let goal: ResponseArrayModel = ResponseArrayModel(category: "goal", contents:  ["산책 30분", "스트레칭 10분", "건강한 식단 2번"])
}

extension WeatherRecommendModel {
    static let weather: WeatherRecommendModel = WeatherRecommendModel(category: "weather", description: "오늘의 날씨는 맑음 입니다. \n실외에서 할 수 있는 활동을 추천해드릴게요.", schedules: ["#산책", "#자전거타기", "#러닝"])
}

extension VideoRecommendModel {
    static let videoList: [VideoRecommendModel] = [
        VideoRecommendModel(
            id: "jfdUL41h15U",
            title: "식후 8분 홈트! 뱃살 쭉쭉 빠지는 소화 걷기 운동! 중년 집에서 7키로 감량!",
            thumbnail: "https://i.ytimg.com/vi/jfdUL41h15U/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "RRPdItYlC7o",
            title: "뱃살, 혈당 다 잡는 최고의 운동법. 매일 식사 후 '이렇게' 해보세요 한달에 -10kg 빠집니다 #치매예방 #비만 #홈트레이닝",
            thumbnail: "https://i.ytimg.com/vi/RRPdItYlC7o/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "sqQpL1wKW6M",
            title: "12분 서서하는 복근운동 홈트레이닝 - 체지방 태우기는 보너스",
            thumbnail: "https://i.ytimg.com/vi/sqQpL1wKW6M/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "oMJuiJ9Rs0w",
            title: "🔥단 12분만에! 뱃살이 무섭게 빠지는 실속 걷기 홈트!! 12-min full body fat burning workout korean",
            thumbnail: "https://i.ytimg.com/vi/oMJuiJ9Rs0w/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "Me3IaZS3CdY",
            title: "🔥밥먹고 바로!🔥뱃살이 무섭게 빠지는 딱 15분 소화 걷기 홈트! 중년 집에서  한달 10키로 감량하기!! 15Min korean walking workout 시니어",
            thumbnail: "https://i.ytimg.com/vi/Me3IaZS3CdY/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "6VlRVsCGuhw",
            title: "누구나 쉽게하는 뱃살 쭉 빼는 10분 집에서 걷기 운동! 중년을 위한 한 달 10kg 챌린지",
            thumbnail: "https://i.ytimg.com/vi/6VlRVsCGuhw/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "L1WdzSo6XhI",
            title: "언니랑 2주 챌린지 💪 논스톱 체지방 태우기 유산소 + 서서하는 복근 딱 15분 홈트",
            thumbnail: "https://i.ytimg.com/vi/L1WdzSo6XhI/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "JxCvhEPm0hg",
            title: "초보 홈트레이닝 여자 살빼기 운동. 다이어트 하시는 분들 딱 2주만 해보세요!",
            thumbnail: "https://i.ytimg.com/vi/JxCvhEPm0hg/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "gFPv-pLT_b8",
            title: "15분! 집에서 하는 필라테스 | 초급 필라테스 홈트 (Pilates for Beginner)",
            thumbnail: "https://i.ytimg.com/vi/gFPv-pLT_b8/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "zDcOqeLGymE",
            title: "8분 루틴 꼭 해주세요! 운동 후 전신 스트레칭  - 8분 쿨다운 스트레칭",
            thumbnail: "https://i.ytimg.com/vi/zDcOqeLGymE/mqdefault.jpg"
        )
    ]
}
