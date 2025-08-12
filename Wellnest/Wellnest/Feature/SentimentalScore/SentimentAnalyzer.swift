//
//  SentimentAnalyzer.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/12/25.
//

import Foundation
import CoreML
import SwiftUI

final class SentimentAnalyzer: ObservableObject {
    private let model = try! KoreanSentiment(configuration: .init())

    /// 결과: (레이블, 신뢰도 0~1)
    func predict(from text: String) -> (label: String, confidence: Double) {
        guard let out = try? model.prediction(text: text) else {
            return ("분석 실패", 0.0)
        }

        let label = out.label
        // 1) 최신 Create ML에서 흔한 키
        if let dict = out.featureValue(for: "labelProbabilities")?.dictionaryValue,
           let prob = dict[label] as? NSNumber {
            return (label, prob.doubleValue)
        }
        // 2) 일부 버전/템플릿에서 쓰는 키
        if let dict = out.featureValue(for: "classProbability")?.dictionaryValue,
           let prob = dict[label] as? NSNumber {
            return (label, prob.doubleValue)
        }

        // 어떤 키가 있는지 몰라서 실패한다면, 키 목록을 한번 확인해 보세요.
        // print("Available features:", out.featureNames)

        // 확률을 못 찾으면 라벨만 반환
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
                Text("감정 분석기")
                    .font(.title2)
                    .bold()

                TextField("문장을 입력하세요", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button("분석하기") {
                    let result = analyzer.predict(from: inputText)
                    resultLabel = result.label
                    confidence = result.confidence
                }
                .buttonStyle(.borderedProminent)
                .padding()

                if !resultLabel.isEmpty {
                    VStack(spacing: 10) {
                        Text("결과: \(resultLabel)")
                            .font(.headline)
                            .foregroundColor(color(for: resultLabel))
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

    func color(for label: String) -> Color {
        switch label {
        case "Pos": return .green
        case "Neg": return .red
        case "Neutral": return .gray
        default: return .black
        }
    }
}
