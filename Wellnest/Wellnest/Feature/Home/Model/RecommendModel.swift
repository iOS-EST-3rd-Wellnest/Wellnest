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
