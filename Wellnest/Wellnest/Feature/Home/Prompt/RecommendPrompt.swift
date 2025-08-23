//
//  RecommendPrompt.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/7/25.
//

import Foundation

struct RecommendPrompt {
    
    private func userInfoStr(_ user: UserEntity) -> String {
        return """
        건강 플래너 AI 프롬프트
        
        사용자 정보:
        - 연령대: \(user.ageRange ?? "")
        - 성별: \(user.gender ?? "")
        - 키: \(user.height ?? 0)cm
        - 몸무게: \(user.weight ?? 0)kg
        - 웰니스목표: \(user.goal ?? "")
        - 선호활동: \(user.activityPreferences ?? "")
        - 활동시간대: \(user.preferredTimeSlot ?? "")
        - 선호날씨: \(user.weatherPreferences ?? "")
        - 건강상태: \(user.healthConditions ?? "")
        """
    }
    
    // MARK: - 해시태그
    func hashtagPrompt(entity: UserEntity) -> String {
        return """
        \(userInfoStr(entity))
        
        위 사용자 정보를 바탕으로 분석하여 해시태그 3개를 생성해주세요.
        중요1: 해시태그는 사용자 정보를 바탕으로 간단한 키워드 형태로 생성 합니다. ex) #20대, #식단관리 등
        중요2: 반드시 아래와 같은 형식으로 생성하며, 아래 형식을 제외한 텍스트는 포함하지 않아야 합니다.
        
        해시태그 형식:
        {
            "contents": ["#해시태그1", "#해시태그2", "#해시태그3"]
        }
        """
    }
    
    // MARK: - 목표
    func goalPrompt(entity: UserEntity) -> String {
        return """
        \(userInfoStr(entity))
        
        위 사용자 정보를 바탕으로 분석하여 오늘 하루 목표 4개를 생성해주세요
        중요1: 반드시 하루동안 달성할 수 있는 다양한 단순한 15글자 이하 목표 생성  ex) 1,000kcal 태우기, 명상 15분 등
        중요2: 반드시 아래와 같은 형식으로 생성하며, 목표를 제외한 텍스트는 포함하지 않아야 합니다.
        
        목표 형식:
        {
            "contents": ["목표1", "목표2", "목표3"]
        }
        """
    }

    // MARK: - 오늘의 한마디
    func quoteOfTheDayPrompt(entity: UserEntity) -> String {
        return """
        \(userInfoStr(entity))
        
        위 사용자 정보를 바탕으로 분석하여 간략한 한 문장의 추천 글귀, 동기부여가되는 한마디 말, 문장, 명언 등의 한 문장을 다양하게 생성해주세요.
        중요1: 반드시 간단한 한 문장
        중요2: 반드시 해당 문장을 제외한 텍스트는 포함하지 않아야 합니다. ex) 내용 처음과 끝에 따옴표(") 제외
        중요3: 형식은 JSON 형식 아님
        """
    }

    // MARK: - 날씨에 따른 활동 추천
    func weatherPrompt(entity: UserEntity, currentWeather: WeatherItem) -> String {
        return """
        \(userInfoStr(entity))
        - 현재 날씨: \(currentWeather.status)
        - 현재 온도: \(currentWeather.temp)℃
        
        위 사용자 정보와 날씨 정보를 바탕으로 분석하여 아래와 같은 형식으로 일정 컨텐츠를 생성해주세요.
        중요1: schedule은 단어로 생성하며, 실내 및 실외 장소와 연관있는 다양한 일정 ex) #헬스장, #음악감상, #명상 등
        중요2: description 첫번째 문장에서 '오늘의 날씨는' 다음으로 현재 날씨에 관련된 텍스트를 생성  
        중요3: description 첫번째 문장 마침표(.)와 다음 문장 사이에 \n포함, 온도는 제외
        중요4: 반드시 아래와 같은 JSON형식으로 생성해야 하며, 다른 텍스트는 반드시 포함되지 않아야 합니다. 
        
        {
            "description": "오늘의 날씨는 비가 오네요. \n실내에서 할 수 있는 일정을 추천해드릴게요.",
            "schedules": ["#추천일정1", "#추천일정2", "#추천일정3"]
        }
        """
    }

    // MARK: - 추천 영상
    func videoPrompt(entity: UserEntity) -> String {
		return """
        \(userInfoStr(entity))
        
        Youtube API를 활용하여 영상을 검색하려 합니다.
        위 사용자 정보를 바탕으로 분석하여 Youtube API에서 검색할 검색어 3개를 생성해주세요.
        중요1: 검색어를 제외한 모든 텍스트는 포함하지 않아야 합니다.
        중요2: 반드시 아래와 같은 형식으로 생성해야 합니다. ex) 고혈압 운동|건강한 식단|홈트레이닝 루틴
        
        검색어 형식:
        검색어1|검색어2|검색어3
        """
    }
}
