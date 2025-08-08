//
//  WeatherPreferenceList.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import Foundation

struct WeatherPreference: SelectableItem {
    let id = UUID()
    let icon: String?
    let category: String
    var isSelected: Bool = false

    static let weathers: [WeatherPreference] = [
        WeatherPreference(icon: "☀️", category: "맑음"),
        WeatherPreference(icon: "🌥️", category: "흐림"),
        WeatherPreference(icon: "🌧️", category: "비"),
        WeatherPreference(icon: "🌨️", category: "눈"),
        WeatherPreference(icon: "🔍", category: "기타"),
        WeatherPreference(icon: "", category: "특별히 없음")
    ]
}
