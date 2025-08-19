//
//  SentimentAnalyzer.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/12/25.
//

import Foundation
import CoreML
import SwiftUI

@MainActor
final class SentimentAnalyzer: ObservableObject {
    private let model: KoreanSentiment

    init() {
        do {
            model = try KoreanSentiment(configuration: .init())
        } catch {
            fatalError("KoreanSentiment 로드 실패: \(error)")
        }
        dumpModelOnce()   // 앱 시작 시 1회 호출
    }

    /// 콘솔 진단: 모델 출력 구조/키/타입과 예측 샘플을 그대로 프린트
    private func dumpModelOnce() {
        do {
            let core = try MLModel(contentsOf: KoreanSentiment.urlOfModelInThisBundle)
            let desc = core.modelDescription
            print("🧩 Model outputs:", desc.outputDescriptionsByName.keys)
            for (k, d) in desc.outputDescriptionsByName {
                print("   - \(k):", d.type) // expected: .string, .dictionary(value: .double)
            }

            // 샘플 텍스트로 직접 Core ML 호출 (래퍼 우회)
            let input = try MLDictionaryFeatureProvider(dictionary: ["text": "오늘 기분이 정말 좋다!"])
            let out = try core.prediction(from: input)
            print("🧪 Raw feature names:", out.featureNames)

            // 모든 피처 값을 있는 그대로 출력
            for name in out.featureNames {
                guard let fv = out.featureValue(for: name) else { continue }
                switch fv.type {
                case .string:
                    print("   • \(name) (String):", fv.stringValue)
                case .dictionary:
                    print("   • \(name) (Dict):")
                    for (k,v) in fv.dictionaryValue {
                        let keyStr = (k as? String) ?? (k as? NSNumber)?.stringValue ?? "<nonstr>"
                        let val = (v as? Double) ?? (v as? NSNumber)?.doubleValue ?? .nan
                        print("       '\(keyStr)' = \(val)")
                    }
                default:
                    print("   • \(name) (type \(fv.type))")
                }
            }
        } catch {
            print("🔴 dumpModelOnce error:", error)
        }
    }

    /// 신뢰도 0 방지: 모든 경우를 커버
    func predict(from text: String) -> (label: String, confidence: Double) {
        guard let out = try? model.prediction(text: text) else {
            return ("분석 실패", 0.0)
        }

        // label 키 자동 탐지
        let label =
            out.featureValue(for: "classLabel")?.stringValue ??
            out.featureValue(for: "label")?.stringValue ??
            "(unknown)"

        // probability 키 자동 탐지
        let probFV =
            out.featureValue(for: "classProbability") ??
            out.featureValue(for: "labelProbability") ??
            out.featureValue(for: "labelProbabilities")

        // [AnyHashable: Any] → [String: Double]
        var probs: [String: Double] = [:]
        if let dict = probFV?.dictionaryValue {
            for (k, v) in dict {
                let key = (k as? String) ?? (k as? NSNumber)?.stringValue ?? ""
                let val = (v as? Double) ?? (v as? NSNumber)?.doubleValue ?? 0.0
                probs[key] = val
            }
        }

        if let p = probs[label] { return (label, p) }
        if let best = probs.max(by: { $0.value < $1.value }) { return (best.key, best.value) }
        return (label, 0.0)
    }
}

struct SentimentView: View {
    @State private var inputText = ""
    @State private var resultLabel = ""
    @State private var confidence: Double = 0.0

    @StateObject private var analyzer = SentimentAnalyzer()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("감정 분석기").font(.title2).bold()

                TextField("문장을 입력하세요", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button("분석하기") {
                    let r = analyzer.predict(from: inputText)
                    resultLabel = r.label
                    confidence = r.confidence
                }
                .buttonStyle(.borderedProminent)
                .padding()

                if !resultLabel.isEmpty {
                    VStack(spacing: 10) {
                        Text("결과: \(resultLabel)")
                            .font(.headline)
                            .foregroundStyle(color(for: resultLabel))
                        Text("신뢰도: \(String(format: "%.2f", confidence * 100))%")
                            .font(.subheadline)
                    }
                    .padding()
                }
                Spacer()
            }
            .padding()
        }
    }

    // 레이블이 "Pos/Neg/Neutral"이 아닐 수도 있으니 유연 매핑
    func color(for label: String) -> Color {
        let lower = label.lowercased()
        if lower.contains("pos") || lower.contains("긍") { return .green }
        if lower.contains("neg") || lower.contains("부정") { return .red }
        if lower.contains("neu") || lower.contains("중립") { return .gray }
        return .primary
    }
}

