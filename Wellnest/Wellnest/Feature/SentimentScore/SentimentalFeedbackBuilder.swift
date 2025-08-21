//
//  SentimentalFeedbackBuilder.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/21/25.
//

import Foundation

public struct SentimentalFeedback {
    public let headline: String        // “오늘 76점, 어제보다 +4. 🙂”
    public let summary: String         // 한 줄 요약
    public let strengths: [String]     // 잘한 점 bullet
    public let suggestions: [String]   // 행동 팁 bullet
    public let push: String            // 푸시 알림용 짧은 문장
}

public struct SentimentalInputs {
    public var score: Double                  // 0..100
    public var deltaFromYesterday: Double?    // 오늘EMA - 어제EMA
    public var weatherSub: Double?            // 0..1
    public var moodSub: Double?
    public var healthSub: Double?
    public var preferredWeather: String?      // "맑음|흐림|비|눈|기타|특별히 없음"
    public var currentCondition: String?      // 현재 상태 스트링
    public init(score: Double, deltaFromYesterday: Double? = nil,
                weatherSub: Double? = nil, moodSub: Double? = nil,
                healthSub: Double? = nil, calendarSub: Double? = nil,
                preferredWeather: String? = nil, currentCondition: String? = nil) {
        self.score = score; self.deltaFromYesterday = deltaFromYesterday
        self.weatherSub = weatherSub; self.moodSub = moodSub
        self.healthSub = healthSub;
        self.preferredWeather = preferredWeather; self.currentCondition = currentCondition
    }
}

public enum SentimentalFeedbackBuilder {

    public static func make(_ i: SentimentalInputs) -> SentimentalFeedback {
        // 1) 점수대 & 이모지
        let (bandTitle, bandEmoji) = band(for: i.score)
        let deltaText = deltaString(i.deltaFromYesterday)
        let headline = "오늘 \(Int(i.score.rounded()))점, \(deltaText) \(bandEmoji)"

        // 2) 강점/보완 카테고리 선별
        let pairs: [(String, Double?)] = [
            ("날씨", i.weatherSub), ("감정", i.moodSub),
            ("건강", i.healthSub)
        ]
        let strengths = pairs.compactMap { name, v in (v ?? 0.5) >= 0.65 ? name : nil }
        let lows = pairs.compactMap { name, v in (v ?? 0.5) <= 0.45 ? name : nil }

        // 3) 한 줄 요약
        let hi = strengths.prefix(2).joined(separator: "·")
        let lo = lows.prefix(2).joined(separator: "·")
        var summary = "\(bandTitle). "
        if !hi.isEmpty { summary += "\(hi) 👍 " }
        if !lo.isEmpty { summary += "\(lo) 보완이 필요해요." }

        // 4) 행동 팁(카테고리별)
        var suggestions: [String] = []
        for name in lows {
            suggestions.append(contentsOf: tips(for: name, inputs: i))
        }
        // 날씨 선호-현재 불일치 특수 팁
        if let w = i.weatherSub, w <= 0.45 {
            if let extra = weatherMismatchTip(preferred: i.preferredWeather, current: i.currentCondition) {
                suggestions.insert(extra, at: 0)
            }
        }
        suggestions = Array(suggestions.prefix(3)) // 최대 3개

        // 5) 강점 문구
        var strengthsLines: [String] = []
        for name in strengths.prefix(3) {
            strengthsLines.append(strengthLine(for: name))
        }

        // 6) 푸시 알림용
        let push: String = {
            switch i.score {
            case 80...: return "오늘 \(Int(i.score))점! 좋은 흐름 유지해요 💪"
            case 65..<80: return "컨디션 \(Int(i.score))점 🙂 리듬 좋아요."
            case 50..<65: return "\(Int(i.score))점 😐 가벼운 루틴으로 끌어올려요."
            case 35..<50: return "\(Int(i.score))점 ⚠️ 짧은 휴식과 수분 보충이 좋아요."
            default: return "\(Int(i.score))점 💤 오늘은 무리하지 말고 회복에 집중하세요."
            }
        }()

        return SentimentalFeedback(
            headline: headline,
            summary: summary.trimmingCharacters(in: .whitespaces),
            strengths: strengthsLines,
            suggestions: suggestions,
            push: push
        )
    }

    // MARK: - Helpers

    private static func band(for score: Double) -> (String, String) {
        switch score {
        case 80...: return ("아주 좋은 컨디션", "✅")
        case 65..<80: return ("무난한 컨디션", "🙂")
        case 50..<65: return ("보통 컨디션", "😐")
        case 35..<50: return ("회복이 필요한 날", "⚠️")
        default: return ("휴식이 필요한 날", "🛌")
        }
    }

    private static func deltaString(_ d: Double?) -> String {
        guard let d else { return "어제와 비슷해요" }
        let absd = abs(d)
        if absd < 1 { return "어제와 비슷해요" }
        let arrow = d > 0 ? "↑" : "↓"
        let sign = d > 0 ? "+" : "−"
        return "어제보다 \(sign)\(Int(absd.rounded())) \(arrow)"
    }

    private static func strengthLine(for name: String) -> String {
        switch name {
        case "감정": return "감정 관리가 좋았어요. 이 흐름을 유지해볼까요?"
        case "건강": return "수면·활동 리듬이 안정적이에요 👍"
        case "일정": return "일정 운영이 균형 잡혀 있어요."
        case "날씨": return "오늘 날씨가 컨디션에 잘 맞아요."
        default: return "\(name) 측면이 좋았어요."
        }
    }

    private static func tips(for name: String, inputs: SentimentalInputs) -> [String] {
        switch name {
        case "감정":
            return ["감정 이모지와 한 문장으로 오늘을 기록해보세요.",
                    "짧은 호흡 3회 · 1분 스트레칭으로 리셋해요."]
        case "건강":
            return ["오늘 수면 시간을 30분 더 확보해보세요.",
                    "가벼운 걷기 10~15분 또는 계단 오르기 추천."]
        case "일정":
            return ["캘린더에 15분 휴식 블록을 한 칸 추가해요.",
                    "업무 과밀이면 중요 1건만 끝내는 전략으로."]
        case "날씨":
            // 날씨는 mismatchTip이 먼저 들어가므로 보조 팁만 반환
            return ["실내/그늘 위주 동선으로 체력 소모를 줄여요."]
        default:
            return ["작은 루틴 하나를 선택해 실행해보세요."]
        }
    }

    private static func weatherMismatchTip(preferred: String?, current: String?) -> String? {
        guard let pref = preferred, let cur = current, pref != "특별히 없음" else { return nil }
        if pref == cur { return nil }
        switch (pref, cur) {
        case ("맑음", "비"): return "비가 와요. 우산 챙기고 실내 위주로 컨디션을 지켜요."
        case ("맑음", "흐림"): return "하늘이 흐려요. 밝은 조명과 가벼운 산책으로 리프레시!"
        case ("흐림", "맑음"): return "햇빛이 강한 날이에요. 모자/선글라스 준비해요."
        case ("비", "맑음"): return "맑은 날! 짧은 산책으로 기분 전환해요."
        case ("눈", _): return "노면이 미끄러울 수 있어요. 이동 시 시간 여유를 주세요."
        default: return "날씨가 선호와 달라요. 동선을 조정해 과부하를 줄여요."
        }
    }
}
