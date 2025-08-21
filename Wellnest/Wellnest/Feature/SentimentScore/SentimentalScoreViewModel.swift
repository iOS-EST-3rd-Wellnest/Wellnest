//
//  SentimentalScoreViewModel.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/21/25.
//

import SwiftUI

final class SentimentalScoreViewModel: ObservableObject {
    // Published 출력
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    @Published var scoreRaw: Double = 0
    @Published var scoreEMA: Double = 0
    @Published var breakdown: (weather: Double?, mood: Double?, health: Double?) = (nil, nil, nil)
    @Published var preferredWeather: String = "특별히 없음"
    @Published var hInputs: HealthInputs?

    private let weatherService = WeatherService()
    var currentWeather: CurrentWeather?

//    private let healthManager = HealthManager()
//    private let eventService: EventKitService
    private let engine = SentimentalEngine()

    // 외부에서 감정 입력을 받아 반영할 수 있게 노출
    var currentMood: MoodInput? = nil

    // MARK: - Public API

    /// 사용자 선호(Wellnest Core Data) + 현재 날씨 + Health/EventKit을 모아 스코어 계산
    @MainActor
    func loadAndCompute(persist: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1) 사용자 선호 날씨 로드
            let user = try CoreDataService.shared.fetch(UserEntity.self).first
            let savedPrefString = user?.weatherPreferences  // 예: "맑음, 비" 또는 nil(=특별히 없음)
            let prefSet = parsePreferenceSet(savedPrefString)
            print(prefSet)
            preferredWeather = savedPrefString ?? "특별히 없음"

            // 2) 현재 날씨
            Task {
                do {
                    let location = try await LocationManager().requestLocation()
                    let lat = location.coordinate.latitude
                    let lon = location.coordinate.longitude

                    // 현재 날씨
                    let currentWeatherItem = try await weatherService.fetchCurrentWeather(lat: lat, lon: lon)
                    self.currentWeather = CurrentWeather(temperatureC: Double(currentWeatherItem.temp), condition: currentWeatherItem.status)
                    print(currentWeather)

                } catch {
                    print(error.localizedDescription)
                }
            }

            // 3) HealthKit/EventKit 스냅샷
            //    - 권한 요청은 앱 진입 시점에서 해두었다고 가정

            // 4) 어제/7일 평균 (EMA 기반)
            let today = Calendar.current.startOfDay(for: Date())
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
//            let ydayEMA = fetchSentimentRecord(for: yesterday)?.emaScore
//            let roll7 = rollingMean(days: 7)

            // 5) 선호 세트 → 엔진 입력용 단일 프리퍼런스 선택
            guard let currentCondition = self.currentWeather else { return }
            let prefKind = pickPreferenceKind(from: prefSet, currentCondition: currentCondition)

            // 7) 계산
//            let calTuple = (busyHours: calSnap.busyHours, hasWorkout: calSnap.hasWorkoutBlock, hasBreak: calSnap.hasBreakBlock)
            let result = engine.compute(
                pref: UserWeatherPreference(preferred: prefKind),
                weather: currentWeather,
                mood: currentMood,
                health: hInputs,
                yesterdayEMA: 50
            )

            // 8) 상태 반영
            scoreRaw = result.raw100
            scoreEMA = result.ema100
            breakdown = result.breakdown

            print("scoreRaw: \(scoreRaw), scoreEMA: \(scoreEMA), breakdown: \(breakdown)")
//
//            // 9) (옵션) Core Data 저장
//            if persist {
//                upsertDailyAndRecord(today: today,
//                                     weather: weather,
//                                     health: healthSnap,
//                                     calendar: calSnap,
//                                     yday: ydayEMA,
//                                     roll7: roll7,
//                                     result: result)
//            }

        } catch {
            lastError = "Sentimental Score 계산 실패: \(error.localizedDescription)"
        }
    }

    // MARK: - 선호 파싱/매핑

    private func parsePreferenceSet(_ saved: String?) -> Set<String> {
        guard let s = saved, !s.isEmpty else { return [] } // nil = "특별히 없음"
        return Set(
            s.split(separator: ",")
             .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
             .filter { !$0.isEmpty }
        )
    }

    private func normalizeCondition(_ s: String) -> String {
        let l = s.lowercased()
        if l.contains("sun") || s.contains("맑") { return "맑음" }
        if l.contains("cloud") || s.contains("흐") || s.contains("구름") { return "흐림" }
        if l.contains("rain") || s.contains("비") { return "비" }
        if l.contains("snow") || s.contains("눈") { return "눈" }
        return "기타"
    }

    /// 다중 선택 선호를 엔진이 쓰는 단일 Kind로 선택
    private func pickPreferenceKind(from set: Set<String>, currentCondition: CurrentWeather) -> UserWeatherPreferenceKind {
        if set.isEmpty || set.contains("특별히 없음") { return .none }
        let cur = normalizeCondition(currentCondition.condition)

        // 현재 날씨가 포함되어 있으면 그대로
        if set.contains(cur) {
            return mapKind(from: cur)
        }

        // 우선순위: 맑음 > 흐림 > 비 > 눈 > 기타
        let order = ["맑음", "흐림", "비", "눈", "기타"]
        for k in order where set.contains(k) {
            return mapKind(from: k)
        }
        return .none
    }

    private func mapKind(from label: String) -> UserWeatherPreferenceKind {
        switch label {
        case "맑음": return .sunny
        case "흐림": return .cloudy
        case "비":   return .rain
        case "눈":   return .snow
        case "기타": return .other
        default:     return .none
        }
    }

    // MARK: - Core Data 보조

//    private func fetchSentimentRecord(for day: Date) -> SentimentEntity? {
//        let day0 = Calendar.current.startOfDay(for: day)
//        let pred = NSPredicate(format: "date == %@", day0 as NSDate)
//        return try? CoreDataService.shared.fetch(SentimentEntity.self, predicate: pred).first
//    }
//
//    private func rollingMean(days: Int) -> Double? {
//        let end = Calendar.current.startOfDay(for: Date())
//        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
//        let pred = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
//        let sort = [NSSortDescriptor(key: "date", ascending: false)]
//        guard let rows = try? CoreDataService.shared.fetch(SentimentEntity.self, predicate: pred, sortDescriptors: sort),
//              !rows.isEmpty else { return nil }
//        return rows.map(\.emaScore).reduce(0, +) / Double(rows.count)
//    }
}

