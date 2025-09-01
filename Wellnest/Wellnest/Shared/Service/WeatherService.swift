//
//  WeatherService.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/12/25.
//

import Foundation

final class WeatherService {
    private let key: String
    private let logger: CrashLogger

    init(logger: CrashLogger = CrashlyticsLogger()) {
        self.logger = logger

        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let plistKey = plist["OpenWeather_API_KEY"] as? String {
            key = plistKey
            logger.log("WeatherService: Secrets loaded (len=\(plistKey.count)")
        } else {
            key = ""
            logger.log("WeatherService: API key not found")
            logger
                .record(
                    NSError(domain: "WeatherService",
                            code: 9001,
                            userInfo: [NSLocalizedDescriptionKey: "OpenWeather API key missing"]),
                    userInfo: nil
                )
        }
    }
    
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> WeatherItem {
        let url = "https://api.openweathermap.org/data/2.5/weather?appid=\(key)&lat=\(lat)&lon=\(lon)&units=metric&lang=kr"

        logger.set(Math.round(lat, places: 4), forKey: "weather.lat")
        logger.set(Math.round(lon, places: 4), forKey: "weather.lon")
        logger.set("metric", forKey: "weather.units")
        logger.set("kr", forKey: "weather.lang")
        logger.log("WeatherService.fetchCurrent start")

        do {
            let weather: WeatherCurrentModel = try await NetworkManager.shared.request(url: url)
            logger.log("WeatherService.fetchCurrent success")
                        logger.set(Int(weather.dt), forKey: "weather.dt")

            return WeatherItem(
                temp: Int(weather.main.temp.rounded()),
                tempMin: Int(weather.main.tempMin.rounded()),
                tempMax: Int(weather.main.tempMax.rounded()),
                status: weather.weather.first?.description ?? "",
                icon: "https://openweathermap.org/img/wn/\(weather.weather.first?.icon ?? "00")@2x.png",
                dt: Date(timeIntervalSince1970: TimeInterval(weather.dt))
            )
        } catch {
            logger.record(error, userInfo: [
                "endpoint": "/data/2.5/weather",
                "units": "metric",
                "lang": "kr"
            ])
            throw error
        }
    }
    
    func fetch5dayWeather(lat: Double, lon: Double) async throws -> [WeatherItem] {
        let url = "https://api.openweathermap.org/data/2.5/forecast?appid=\(key)&lat=\(lat)&lon=\(lon)&units=metric&lang=kr"

        logger.set(Math.round(lat, places: 4), forKey: "forecast.lat")
        logger.set(Math.round(lon, places: 4), forKey: "forecast.lon")
        logger.log("WeatherService.fetch5day start")

        do {
            let weather: WeatherListModel = try await NetworkManager.shared.request(url: url)
            if weather.list.isEmpty {
                logger.record(NSError(domain: "WeatherService", code: 9002,
                                      userInfo: [NSLocalizedDescriptionKey: "Forecast list empty"]),
                              userInfo: ["endpoint": "/data/2.5/forecast"])
            } else {
                logger.set(weather.list.count, forKey: "forecast.slotCount")
            }
            let items = try await makeFiveDayWeather(lat: lat, lon: lon, using: weather)
            logger.log("WeatherService.fetch5day success items=\(items.count)")
            logger.set(items.count, forKey: "forecast.itemsCount")
            return items
        } catch {
            print("🛑 error: \(error.localizedDescription)")
            throw error
        }
    }
    
	private func makeFiveDayWeather(lat: Double, lon: Double, using forecast: WeatherListModel) async throws -> [WeatherItem] {
        // 1) 현재 날씨(메서드 내부에서 별도 호출)
        let current = try await fetchCurrentWeather(lat: lat, lon: lon)
        
        // 2) KST 달력/시간대
        let kst = TimeZone(identifier: "Asia/Seoul") ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kst
        
        // 오늘(현재 날씨가 속한 일자) 자정
        let todayStart = cal.startOfDay(for: current.dt)
        
        // 3) 예보 슬롯을 Date로 변환 (dt는 초 단위 유닉스 타임)
        let slots: [(date: Date, entry: WeatherList)] = forecast.list.map {
            (Date(timeIntervalSince1970: TimeInterval($0.dt)), $0)
        }
        
        // 4) KST 기준 일자별 그룹핑
        let grouped = Dictionary(grouping: slots) { cal.startOfDay(for: $0.date) }
        
        // 5) 오늘 제외(내일 이후)만 정렬
        let futureDays = grouped.keys.filter { $0 > todayStart }.sorted()
        
        // 6) 날짜별 요약 생성 (정오 슬롯 ‘딱’ 한 개만 사용)
        var dayItems: [WeatherItem] = []
        for dayStart in futureDays {
            guard let daySlots = grouped[dayStart], !daySlots.isEmpty else { continue }
            
            let repNoon = daySlots.first { slot in
                let comps = cal.dateComponents([.hour, .minute], from: slot.date)
                return comps.hour == 12 && comps.minute == 0
            }
            guard let rep = repNoon else { continue }
            
            // 통계값: 평균/최저/최고 (정수 반올림)
            let temps    = daySlots.map { $0.1.main.temp }
            let tempAvg  = temps.reduce(0, +) / Double(max(temps.count, 1))
            let tempMin  = daySlots.map { $0.1.main.tempMin }.min() ?? 0
            let tempMax  = daySlots.map { $0.1.main.tempMax }.max() ?? 0
            
            // 상태/아이콘: 대표 슬롯 기준 (status는 description)
            let status   = rep.1.weather.first?.description ?? rep.1.weather.first?.main.rawValue ?? ""
            let iconCode = rep.1.weather.first?.icon ?? ""
            let iconURL  = "https://openweathermap.org/img/wn/\(iconCode)@2x.png"
            
            dayItems.append(
                WeatherItem(
                    temp:    Int(tempAvg.rounded()),
                    tempMin: Int(tempMin.rounded(.down)),
                    tempMax: Int(tempMax.rounded(.up)),
                    status:  status,
                    icon:    iconURL,
                    dt:      rep.0
                )
            )
        }
        
        // 7) 최종: 현재 + 다음 4일(최대 5개로 제한)
        return [current] + Array(dayItems.prefix(4))
    }
    
}

enum Math {
    static func round(_ value: Double, places: Int) -> Double {
        let p = pow(10.0, Double(places))
        return (value * p).rounded() / p
    }
}
