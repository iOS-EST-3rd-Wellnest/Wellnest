//
//  VideoRecommendModel.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/6/25.
//

import Foundation
import SwiftUI

struct VideoRecommendModel: Identifiable {
    let id: String
    let title: String
    let thumbnail: String
}

extension VideoRecommendModel {
    static let videoList: [VideoRecommendModel] = [
        VideoRecommendModel(
            id: "ezEs6sbSsOg",
            title: "뻑적지근한 몸, 요가 수련으로 회복하세요 | 15분 모닝 요가 | 요가소년 042",
            thumbnail: "https://i.ytimg.com/vi/ezEs6sbSsOg/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "feouqxW87gE",
            title: "러닝, 신발과 옷이 전부가 아닙니다.",
            thumbnail: "https://i.ytimg.com/vi/feouqxW87gE/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "eTuWJbdqHMc",
            title: "(10분) 정말 매일 해야 하는 전신 요가 스트레칭(아침, 저녁 수시로!) fullbody morning yoga stretch",
            thumbnail: "https://i.ytimg.com/vi/eTuWJbdqHMc/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "tZEZNsuDkLY",
            title: "매일하기 좋은 15분 데일리 스트레칭 | 기초 요가 스트레칭, 전신 스트레칭",
            thumbnail: "https://i.ytimg.com/vi/tZEZNsuDkLY/mqdefault.jpg"
        ),
        VideoRecommendModel(
            id: "Y41bo1WG9fo",
            title: "\"온전히 나 자신을 느낄 수 있어요\" 요즘 MZ들이 러닝에 빠진 이유를 알아봤습니다!",
            thumbnail: "https://i.ytimg.com/vi/Y41bo1WG9fo/mqdefault.jpg"
        )
    ]
}
