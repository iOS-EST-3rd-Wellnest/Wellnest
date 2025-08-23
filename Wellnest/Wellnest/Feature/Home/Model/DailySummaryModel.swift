//
//  DailySummaryModel.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/18/25.
//
import Foundation

struct DailySummaryModel {
    let date: Date
    let hashtags: [String]
    let goals: [String]
    let quote: String
    let weather: WeatherRecommendModel?
    let video: [VideoRecommendModel]
}
