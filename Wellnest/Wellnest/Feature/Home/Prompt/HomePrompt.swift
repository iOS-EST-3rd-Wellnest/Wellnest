//
//  HomePrompt.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/7/25.
//

import Foundation

struct HomePrompt {
    
    func promptStr() -> String {
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
