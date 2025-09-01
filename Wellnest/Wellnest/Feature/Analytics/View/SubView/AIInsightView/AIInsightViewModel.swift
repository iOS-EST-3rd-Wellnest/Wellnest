//
//  AIInsightViewModel.swift
//  Wellnest
//
//  Updated for new Repository/DTO/Domain pipeline
//

import Foundation
import SwiftUI

@MainActor
final class AIInsightViewModel: ObservableObject {
    @Published var insightText: AttributedString? = "AI가 응답을 생성중입니다..."

    init() {
        Task { await loadAIInsight() }
    }

    func loadAIInsight() async {
        do {
            // (1) DTO + 연결 상태 함께 수신 (칼로리 제거된 repo)
            let (exerciseDTO, _, connection) = try await HealthManagerRepository.shared.loadAllWithErrorHandling()

            // (2) 연결 상태 반영해서 도메인 매핑
            let exercise = ExerciseData.fromDTO(exerciseDTO, isConnected: connection.stepsGranted)

            // (3) AI 호출
            let result = await fetchAIInsight(exercise: exercise)

            // (4) UI 업데이트는 메인 액터에서
            await MainActor.run {
                self.insightText = result
            }
        } catch {
            await MainActor.run {
                var text = AttributedString("AI 응답을 가져올 수 없습니다.")
                text.foregroundColor = .red
                self.insightText = text
            }
        }
    }
}

// MARK: - AI 호출
private extension AIInsightViewModel {
    func fetchAIInsight(exercise: ExerciseData?) async -> AttributedString? {
        do {
            let aiService = AIServiceProxy()
            let prompt = Self.insightPrompt(exercise: exercise)
            let result = try await aiService.request(prompt: prompt)

            if let json = await aiService.extractJSONFromResponse(result.content),
               let data = json.data(using: .utf8),
               let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sentence = decoded["sentence"] as? String {
                return try? AttributedString(markdown: sentence)
            } else {
                return try? AttributedString(markdown: result.content)
            }
        } catch {
            var text = AttributedString("AI 응답을 가져올 수 없습니다.")
            text.foregroundColor = .red
            return text
        }
    }

    static func insightPrompt(exercise: ExerciseData?) -> String {
        let block = exercise?.aiPromptBlock ?? "건강 데이터가 없음"
        return """
        \(block)

        위 데이터를 참조해서 내가 오늘 어떻게 건강관리를 하면 좋을지 40자 제한, 한 문장으로 만들어줘.
        응원하는 얘기도 좋아. 만약 데이터가 없으면 니가 추천해 주고 싶은 건강관리 말을 만들어줘.

        응답은 반드시 다음 JSON 형식으로 해줘:
        {"sentence": "여기에 건강관리 문장"}
        """
    }
}

// MARK: - 프롬프트 빌더 (걸음 전용)
private extension ExerciseData {
    /// 일별 포인트에서 Double 배열만 추출(값만)
    func values(_ points: [DailyPoint]) -> [Double] { points.map(\.value) }

    /// 평균 헬퍼
    func avg(_ arr: [Double]) -> Int {
        guard !arr.isEmpty else { return 0 }
        return Int((arr.reduce(0, +) / Double(arr.count)).rounded())
    }

    var aiPromptBlock: String {
        // 시계열
        let steps7  = values(steps7dDaily)
        let steps30 = values(steps30dDaily)

        // 요약
        let steps7Avg  = avg(steps7)
        let steps30Avg = avg(steps30)

        // 오늘 3시간 단위 버킷 합(정합/리듬감 파악용)
        let today3hTotal = Int(stepsToday3hBuckets.map(\.value).reduce(0, +).rounded())

        // 간단 추세(최근 7일 평균 vs 그 이전 7일 평균) — 데이터 없으면 생략
        var WoWText = "N/A"
        if steps30.count >= 14 {
            let last7 = Array(steps30.suffix(7))
            let prev7 = Array(steps30.dropLast(7).suffix(7))
            let a = last7.reduce(0, +) / 7.0
            let b = prev7.reduce(0, +) / 7.0
            if b > 0 {
                let pct = Int(((a - b) / b * 100).rounded())
                WoWText = "\(pct >= 0 ? "+" : "")\(pct)%"
            }
        }

        return """
        운동 데이터 AI 프롬프트(걸음 전용)
        - 오늘 걸음 수 합계: \(stepsTodayTotal)보 (3시간 버킷 합계: \(today3hTotal)보)

        최근 7일(일별):
        - 걸음(평균): \(steps7Avg) 보

        최근 30일(일별):
        - 걸음(평균): \(steps30Avg) 보

        추세:
        - 주간 변화율(최근 7일 평균 vs 이전 7일 평균): \(WoWText)

        원시 시계열(요약):
        - 7d steps: \(steps7.prefix(7).map { Int($0) })
        - 30d steps(sample 10): \(steps30.prefix(10).map { Int($0) })
        """
    }
}
