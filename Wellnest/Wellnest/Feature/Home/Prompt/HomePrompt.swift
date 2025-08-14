//
//  HomePrompt.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/7/25.
//

import Foundation

struct HomePrompt {
    func quoteOfTheDayPrompt() -> String {
        return """
        건강 플래너 AI 프롬프트
        
        사용자 정보:
        - 연령대: 30대
        - 성별: 남자
        - 키: 185cm
        - 몸무게: 71kg
        - 웰니스목표: 특별히 업음
        - 선호활동: 명상,헬스
        - 활동시간대: 밤/새벽
        - 선호날씨: 맑음,눈
        - 건강상태: 수면 문제
        
        위 사용자 정보를 바탕으로 분석하여 간략한 한 문장의 추천 글귀, 동기부여가되는 한마디 말, 문장, 명언 등을 생성해주세요.
        """
    }
    
    func videoPrompt() -> String {
		return """
        건강 플래너 AI 프롬프트
        
        사용자 정보:
        - 연령대: 20대
        - 성별: 남자
        - 키: 175cm
        - 몸무게: 81kg
        - 웰니스목표: 체중 감량 또는 증가
        - 선호활동: 걷기
        - 활동시간대: 특별히 없음
        - 선호날씨: 흐림,눈
        - 건강상태: 과체중
        
        Youtube API를 활용하여 영상을 검색하려 합니다.
        위 사용자 정보를 바탕으로 분석하여 Youtube API에서 검색할 검색어를 자연어 형태로 생성해주세요.
        """
    }
}
