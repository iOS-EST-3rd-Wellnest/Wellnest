//
//  ScoreModel.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/21/25.
//

import Foundation

public enum UserWeatherPreferenceKind: String, CaseIterable { case sunny = "맑음", cloudy = "흐림", rain = "비", snow = "눈", other = "기타", none = "특별히 없음" }

public struct UserWeatherPreference {
    public var preferred: UserWeatherPreferenceKind
    public init(preferred: UserWeatherPreferenceKind) { self.preferred = preferred }
}

public struct CurrentWeather {
    public var temperatureC: Double
    public var condition: String // e.g. "맑음" | "흐림" | "비" | "눈" | others
    public init(temperatureC: Double, condition: String) {
        self.temperatureC = temperatureC; self.condition = condition
    }
}

public struct MoodInput {
    public var emoji: String?
    public var text: String?
    public init(emoji: String?, text: String?) { self.emoji = emoji; self.text = text }
}

public struct HealthInputs { public var sleepHours: Double?; public var steps: Double?; public var averageHR: Double?; public var activeCalories: Double? }

fileprivate enum HealthScorer {
    static func score(_ h: HealthInputs) -> Double {
        let sleep = h.sleepHours.map { Norm.inverseAroundIdeal($0, ideal: 7.5, lower: 3, upper: 11) } ?? 0.5
        let steps = h.steps.map { Norm.clamp(Double($0) / 10_000.0, 0, 1) } ?? 0.5
        let kcal  = h.activeCalories.map { Norm.clamp($0 / 500.0, 0, 1) } ?? 0.5
        let rhr   = h.averageHR.map { Norm.inverseAroundIdeal($0, ideal: 60, lower: 45, upper: 90) } ?? 0.5
        return 0.4*sleep + 0.25*steps + 0.2*kcal + 0.15*rhr
    }
}

fileprivate enum WeatherScorer {
    static func normalizeCondition(_ s: String) -> String {
        let l = s.lowercased()
        if l.contains("sun") || s.contains("맑") { return "맑음" }
        if l.contains("cloud") || s.contains("흐") { return "흐림" }
        if l.contains("rain") || s.contains("비") { return "비" }
        if l.contains("snow") || s.contains("눈") { return "눈" }
        return "기타"
    }
    static func conditionMatch(preferred: UserWeatherPreferenceKind, current: String) -> Double {
        let cur = normalizeCondition(current)
        switch preferred {
        case .none:  return 0.6
        case .other: return cur == "기타" ? 1.0 : 0.5
        case .sunny: return cur == "맑음" ? 1.0 : (cur == "흐림" ? 0.7 : 0.3)
        case .cloudy:return cur == "흐림" ? 1.0 : (cur == "맑음" ? 0.7 : 0.4)
        case .rain:  return cur == "비"   ? 1.0 : 0.3
        case .snow:  return cur == "눈"   ? 1.0 : 0.3
        }
    }
    static func score(pref: UserWeatherPreference, weather: CurrentWeather) -> Double {
        let cs = conditionMatch(preferred: pref.preferred, current: weather.condition)
        let season: Season = Season.season()
        let ts = temperatureScore(current: weather.temperatureC, pref: pref.preferred, season: season)
        return 0.7*cs + 0.3*ts
    }

    /// bandMatch와 결합하여 현재 기온 점수화
    static func temperatureScore(current tempC: Double, pref: UserWeatherPreferenceKind, season: Season) -> Double {
        let band = preferredTempBand(for: pref, season: season)
        return Norm.bandMatch(value: tempC, low: band.low, high: band.high, slack: band.slack)
    }

    /// 선호 텍스트(=날씨 유형)와 시즌으로 "선호 온도 구간"을 추정
    static func preferredTempBand(for pref: UserWeatherPreferenceKind, season: Season) -> (low: Double, high: Double, slack: Double) {
        // 휴리스틱 기본값(섭씨)
        switch season {
        case .spring, .autumn:
            switch pref {
            case .sunny:  return (20, 26, 5)   // 맑음은 약간 따뜻해도 선호
            case .cloudy: return (17, 22, 5)
            case .rain:   return (14, 20, 5)
            case .snow:   return ( -1,  4, 5)  // 비정상 시즌 대비용
            case .other:  return (18, 24, 5)
            case .none:   return (18, 24, 6)
            }
        case .summer:
            switch pref {
            case .sunny:  return (22, 28, 6)   // 강한 일사 고려해 약간 낮춘 범위
            case .cloudy: return (20, 26, 6)
            case .rain:   return (18, 24, 6)
            case .snow:   return (  0,  4, 6)
            case .other:  return (20, 26, 6)
            case .none:   return (20, 26, 6)
            }
        case .winter:
            switch pref {
            case .sunny:  return ( 2,  8, 3)
            case .cloudy: return ( 0,  6, 3)
            case .rain:   return ( 0,  5, 3)
            case .snow:   return (-3,  3, 3)
            case .other:  return ( 0,  6, 3)
            case .none:   return ( 0,  6, 3)
            }
        }
    }

}

fileprivate enum Norm {
    static func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double { min(max(v, min(a,b)), max(a,b)) }
    static func sigmoid(_ x: Double) -> Double { 1 / (1 + exp(-x)) }
    static func bandMatch(value: Double, low: Double, high: Double, slack: Double = 5.0) -> Double {
        if value >= low && value <= high { return 1 }
        let d = value < low ? (low - value) : (value - high)
        return max(0, 1 - d / slack)
    }
    static func inverseAroundIdeal(
        _ value: Double,
        ideal: Double,
        lower: Double,
        upper: Double
    ) -> Double {
        let d = abs(value - ideal)
        let maxD = Swift.max(abs(lower - ideal), abs(upper - ideal))
        return 1 - Swift.min(d / maxD, 1)
    }
}

enum Season { case spring, summer, autumn, winter }

extension Season {
    /// 현재(또는 전달한 날짜)의 계절을 반환
    static func season(for date: Date = Date(), in calendar: Calendar = .current) -> Season {
        let month = calendar.component(.month, from: date)
        switch month {
        case 3...5:   return .spring   // 3~5월
        case 6...8:   return .summer   // 6~8월
        case 9...11:  return .autumn   // 9~11월
        default:      return .winter   // 12~2월
        }
    }
}

public struct SentimentalEngine {
    public var weights: SentimentalWeights = .init()
    public var alphaEMA: Double = 0.35

    public init() {}

    func compute(
        pref: UserWeatherPreference,
        weather: CurrentWeather?,
        mood: MoodInput?,
        health: HealthInputs?,
        yesterdayEMA: Double?
    ) -> (raw100: Double, ema100: Double, breakdown: (weather: Double?, mood: Double?, health: Double?)) {

        let wSub = weather.map { WeatherScorer.score(pref: pref, weather: $0) }
        let mSub = mood.map { SimpleMoodNLP.score(emoji: $0.emoji, text: $0.text) }
        let hSub = health.map { HealthScorer.score($0) }

        let present: [(Double, Double)] = [
            wSub.map { ($0, weights.weather) },
            mSub.map { ($0, weights.mood) },
            hSub.map { ($0, weights.health) }
        ].compactMap { $0 }

        let sumW = present.map { $0.1 }.reduce(0, +)
        let raw01: Double = sumW == 0 ? 0.5 : present.reduce(0) { $0 + $1.0 * ($1.1 / sumW) }
        let raw100 = 100 * raw01
        let ema100 = (yesterdayEMA == nil) ? raw100 : (alphaEMA * raw100 + (1 - alphaEMA) * yesterdayEMA!)
        return (raw100, ema100, (wSub, mSub, hSub))
    }
}

// MARK: - SentimentalPipeline.swift (Core Data glue via CoreDataService)

public final class SentimentalPipeline {
    private let engine = SentimentalEngine()
    private let service = CoreDataService.shared

    public init() {}

    // MARK: Fetch helpers
//    private func fetchRecord(for day: Date) -> SentimentEntity? {
//        let day0 = Calendar.current.startOfDay(for: day)
//        let pred = NSPredicate(format: "date == %@", day0 as NSDate)
//        return try? service.fetch(SentimentEntity.self, predicate: pred, sortDescriptors: nil).first
//    }

//    private func rollingMean(days: Int) -> Double? {
//        let end = Calendar.current.startOfDay(for: Date())
//        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
//        let pred = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
//        let sort = [NSSortDescriptor(key: "date", ascending: false)]
//        guard let rows = try? service.fetch(SentimentEntity.self, predicate: pred, sortDescriptors: sort),
//              !rows.isEmpty else { return nil }
//        return rows.map(\.emaScore).reduce(0, +) / Double(rows.count)
//    }
}

fileprivate enum SimpleMoodNLP {
    static let emojiMap: [String: Double] = [
        "😀":1.00,"🥰":0.95,"😊":0.85,"🙂":0.75,
        "😐":0.50,"🙁":0.35,"😞":0.25,"😡":0.10,"😭":0.05
    ]
    static let pos = ["좋","행복","만족","편안","설렘","즐겁","최고","뿌듯"]
    static let neg = ["피곤","짜증","우울","불안","스트레스","아픔","최악","힘들"]

    static func score(emoji: String?, text: String?) -> Double {
        let base = emoji.flatMap { emojiMap[$0] } ?? 0.5
        guard let t = text?.lowercased(), !t.isEmpty else { return base }
        var delta = 0.0
        if pos.contains(where: { t.contains($0) }) { delta += 0.1 }
        if neg.contains(where: { t.contains($0) }) { delta -= 0.1 }
        return max(0, min(1, base + delta))
    }
}

public struct SentimentalWeights {
    public var weather: Double = 0.25
    public var mood: Double    = 0.30
    public var health: Double  = 0.30
    public var calendar: Double = 0.15
}
