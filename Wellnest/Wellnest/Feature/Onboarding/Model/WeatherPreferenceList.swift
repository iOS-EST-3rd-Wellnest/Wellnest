//
//  WeatherPreferenceList.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import Foundation

struct WeatherPreference: SelectableItem {
    let id = UUID()
    let icon: String
    let title: String
    var isSelected: Bool = false

    static let weathers: [WeatherPreference] = [
        WeatherPreference(icon: "☀️", title: "맑음"),
        WeatherPreference(icon: "🌥️", title: "흐림"),
        WeatherPreference(icon: "🌧️", title: "비"),
        WeatherPreference(icon: "🌨️", title: "눈"),
        WeatherPreference(icon: "❔", title: "기타"),
        WeatherPreference(icon: "💬", title: "특별히 없음")
    ]
}
