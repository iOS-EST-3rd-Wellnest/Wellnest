//
//  WeatherModel.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/12/25.
//
import Foundation

// MARK: - WeatherItem
struct WeatherItem {
    let temp: Int
    let tempMin: Int
    let tempMax: Int
    
    let status: String
    let icon: String
    
    let dt: Date
}

// MARK: - WeatherListModel
struct WeatherListModel: Codable {
    let cod: String
    let message, cnt: Int
    let list: [WeatherList]
}

// MARK: - WeatherCurrentModel
struct WeatherCurrentModel: Codable {
    let weather: [Weather]
    let main: MainInfo
    let dt: Int
    let name: String
    let cod: Int
}

// MARK: - WeatherList
struct WeatherList: Codable {
    let dt: Int
    let main: MainInfo
    let weather: [Weather]
    let dtTxt: String

    enum CodingKeys: String, CodingKey {
        case dt, main, weather
        case dtTxt = "dt_txt"
    }
}

// MARK: - MainInfo
struct MainInfo: Codable {
    let temp, tempMin, tempMax: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case tempMin = "temp_min"
        case tempMax = "temp_max"
    }
}

// MARK: - Weather
struct Weather: Codable {
    let id: Int
    let main: MainEnum
    let description, icon: String
}

enum MainEnum: String, Codable {
    case clear = "Clear"
    case clouds = "Clouds"
    case rain = "Rain"
    case snow = "Snow"
    case drizzle = "Drizzle"
    case thunderstorm = "Thunderstorm"
    case mist = "Mist"
    case smoke = "Smoke"
    case haze = "Haze"
    case dust = "Dust"
    case fog = "Fog"
    case sand = "Sand"
    case ash = "Ash"
    case squall = "Squall"
    case tornado = "Tornado"
}
