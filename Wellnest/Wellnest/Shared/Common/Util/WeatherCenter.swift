//
//  WeatherCenter.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/19/25.
//
import Foundation

@MainActor
final class WeatherCenter {
    static let shared = WeatherCenter()
    private init() {}

    private let weatherService = WeatherService()
    private let locationManager = LocationManager()

    private var forecast: [WeatherItem] = []
    // 현재 진행 중인 로드 작업을 보관
    private var currentTask: Task<[WeatherItem], Never>?

    /// 앱 시작 시 한 번 미리 로드)
    func preloadIfNeeded() async {
        if forecast.isEmpty {
            _ = await refresh()
        }
    }

    /// 강제 새로고침: 이미 로딩 중이면 그 작업을 기다리고, 아니면 새 작업 시작
    func refresh() async -> [WeatherItem] {
        if let task = currentTask {
            // 이미 로딩 중이면 같은 작업 결과를 공유
            return await task.value
        }

        let weatherTask = Task { [weak self] () -> [WeatherItem] in
            guard let self else { return [] }

            do {
                let loc = try await self.locationManager.requestLocation()
                let list = try await self.weatherService.fetch5dayWeather(
                    lat: loc.coordinate.latitude,
                    lon: loc.coordinate.longitude
                )

                self.forecast = list
                return list
            } catch {
                print("날씨 예보 로딩 실패:", error.localizedDescription)
                return []
            }
        }

        currentTask = weatherTask
        let result = await weatherTask.value
        currentTask = nil
        return result
    }

    /// 캐시 있으면 즉시, 없으면 로드 완료까지 기다렸다가 반환
    func waitForForecast() async -> [WeatherItem] {
        if !forecast.isEmpty { return forecast }
        return await refresh()
    }
}

extension WeatherCenter {
    func forecastByDay(calendar: Calendar = .current) async -> [Date: WeatherItem] {
        let list = await waitForForecast()
        let cal = calendar
        var dict: [Date: WeatherItem] = [:]

        for item in list {
            let key = cal.startOfDay(for: item.dt)
            if dict[key] == nil {
                dict[key] = item
            }
        }
        return dict
    }
}
