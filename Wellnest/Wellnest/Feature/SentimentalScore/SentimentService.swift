//
//  SentimentService.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/19/25.
//

import Foundation
import CoreML

final class SentimentService {
    static let shared = SentimentService()
    private let model: KoreanSentiment

    private init() {
        do {
            model = try KoreanSentiment(configuration: .init())
        } catch {
            fatalError("KoreanSentiment 로드 실패: \(error)")
        }
    }

    /// note 텍스트 → (라벨, 신뢰도0~1). 확률 출력이 없는 모델이면 1.0로 폴백.
    func predict(from text: String) -> (label: String, confidence: Double)? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard let out = try? model.prediction(text: text) else { return nil }

        // 라벨
        let label =
            out.featureValue(for: "classLabel")?.stringValue ??
            out.featureValue(for: "label")?.stringValue ??
            "(unknown)"

        // 확률 딕셔너리(있으면 사용)
        let probFV =
            out.featureValue(for: "classProbability") ??
            out.featureValue(for: "labelProbability") ??
            out.featureValue(for: "labelProbabilities")

        if let dict = probFV?.dictionaryValue {
            var probs: [String: Double] = [:]
            for (k, v) in dict {
                let key = (k as? String) ?? (k as? NSNumber)?.stringValue ?? ""
                let val = (v as? Double) ?? (v as? NSNumber)?.doubleValue ?? 0.0
                probs[key] = val
            }
            if let p = probs[label] {
                return (label, p)
            } else if let best = probs.max(by: { $0.value < $1.value }) {
                // 라벨 문자열이 살짝 다를 때 최댓값으로 폴백
                return (best.key, best.value)
            }
        }
        // 확률 없으면 1.0로 폴백(라벨만 출력하는 모델인 경우)
        return (label, 1.0)
    }
}
