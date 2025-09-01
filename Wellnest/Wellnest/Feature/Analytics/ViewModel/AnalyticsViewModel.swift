//
//  AnalyticsViewModel.swift
//  Wellnest
//
//  Created by junil on 8/14/25.
//

import Foundation
import CoreData
import HealthKit

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var healthData: HealthData
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Repository / 설정
    private let repo = HealthManagerRepository.shared
    private let userDefaults = UserDefaultsManager.shared

    init() {
        self.healthData = HealthData(
            userName: "사용자",
            aiInsight: AIInsightData(message: "데이터를 불러오는 중..."),
            exercise: .init(
                stepsTodayTotal: 0,
                stepsToday3hBuckets: [],
                steps7dDaily: [],
                steps7dTotal: 0,
                steps7dAverage: 0,
                steps30dDaily: [],
                steps30dTotal: 0,
                steps30dAverage: 0,
                isHealthKitConnected: false
            ),
            sleep: .init(
                sleepTodayMinutes: 0,
                sleep7dDailyMinutes: [],
                sleep7dTotalMinutes: 0,
                sleep7dAverageMinutes: 0,
                sleep30dDailyMinutes: [],
                sleep30dTotalMinutes: 0,
                sleep30dAverageMinutes: 0,
                isHealthKitConnected: false
            )
        )
        Task { await load() }
    }

    func load() async {
        await loadWithBetterErrorHandling()
    }

    func loadWithBetterErrorHandling() async {
        guard userDefaults.isHealthKitEnabled else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let (exDTO, slDTO, conn) = try await repo.loadAllWithErrorHandling()

            let exercise = ExerciseData.fromDTO(exDTO, isConnected: conn.stepsGranted)
            let sleep = SleepData.fromDTO(slDTO, isConnected: conn.sleepGranted)

            let insight = generateAIInsight(
                stepsToday: exercise.stepsTodayTotal,
                sleepTodayMinutes: sleep.sleepTodayMinutes
            )

            self.healthData = HealthData(
                userName: getUserName(),
                aiInsight: insight,
                exercise: exercise,
                sleep: sleep
            )
            self.errorMessage = nil

        } catch {
            print("❌ loadWithBetterErrorHandling 실패: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }

    // 간단 로컬 규칙 인사이트 (칼로리 제거)
    private func generateAIInsight(stepsToday: Int, sleepTodayMinutes: Int) -> AIInsightData {
        var msgs: [String] = []
        if stepsToday >= 10_000 {
            msgs.append("오늘 \(stepsToday)보! 대단해요 👏")
        }

        let h = Double(sleepTodayMinutes) / 60.0
        if (7...9).contains(h) {
            msgs.append("수면이 충분해요. 컨디션 좋아요 😴")
        } else if h < 6 {
            msgs.append("수면이 부족해 보여요. 오늘은 일찍 잠들어볼까요? 🌙")
        }

        return AIInsightData(message: msgs.first ?? "데이터가 쌓일수록 더 똑똑해질게요!")
    }

    // 사용자명 로드
    func getUserName() -> String {
        let coreDataService = CoreDataService.shared
        do {
            let req = NSFetchRequest<NSManagedObject>(entityName: "UserEntity")
            req.fetchLimit = 1
            let users = try coreDataService.context.fetch(req)
            if let user = users.first,
               let nickname = user.value(forKey: "nickname") as? String,
               !nickname.isEmpty {
                return nickname
            }
        } catch {
            print("CoreData에서 사용자 닉네임 가져오기 실패: \(error)")
        }
        return "사용자"
    }
}
