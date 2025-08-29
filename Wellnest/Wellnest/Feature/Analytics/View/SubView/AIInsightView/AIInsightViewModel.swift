//
//  AIInsightViewModel.swift
//  Wellnest
//
//  Created by Jusung Kye on 8/28/25.
//

import Foundation
import SwiftUI
import HealthKit

final class AIInsightViewModel: ObservableObject {
    @Published var insightText: AttributedString? = "AI가 응답을 생성중입니다..."
    
    private let healthManager = HealthManager.shared
    
    init() {
        Task { await loadAIInsight() }
    }
    
    func loadAIInsight() async {
        let healthData = await loadExerciseData()
        let result = await fetchAIInsight()
        
        await MainActor.run {
            self.insightText = result
        }
    }
}

private extension AIInsightViewModel {
    func fetchAIInsight() async -> AttributedString? {
        do {
            //            guard let userInfo else { return "" }
            let aiService = AIServiceProxy()
            let result = try await aiService.request(prompt: Self.insightPrompt(user: nil))
            print("##### ai result: \(result)")
            return try? AttributedString(markdown: result.content)
        } catch {
            print("오늘의 한마디 요청 실패:", error.localizedDescription)
            return "AI 응답을 가져올 수 없습니다."
        }
    }
    
    static func insightPrompt(user: UserEntity?) -> String {
        return """
                iOS 개발자의 미래는 어떻다고 생각해? 
                중요1: 반드시 간단한 한 문장으로
                중요2: 반드시 해당 한글과 영어를 제외한 문자는 제외시켜줘. *도 제외시켜줘
                중요3: 형식은 JSON 형식 아님
                """
    }
}
    
private extension AIInsightViewModel {
    func loadExerciseData() async -> ExerciseData {
        print("❤️ 운동 데이터 로드 시작")

        guard HKHealthStore.isHealthDataAvailable() else {
            print("❤️ HealthKit을 사용할 수 없음")
            return ExerciseData(
                averageSteps: 0, stepsChange: 0, averageCalories: 0, caloriesChange: 0,
                weeklySteps: Array(repeating: 0, count: 7), monthlySteps: Array(repeating: 0, count: 8),
                dailyStepsChange: 0, weeklyStepsChange: 0, monthlyStepsChange: 0,
                dailyCaloriesChange: 0, weeklyCaloriesChange: 0, monthlyCaloriesChange: 0
            )
        }

        let authCheck = await healthManager.finalAuthSnapshot()
        print("❤️ HealthKit 권한 상태:")
        print("❤️ - 누락된 권한: \(authCheck.missingCore)")

        if !authCheck.missingCore.isEmpty {
            print("❤️ HealthKit 권한이 없어서 빈 데이터 반환")
            return ExerciseData(
                averageSteps: 0, stepsChange: 0, averageCalories: 0, caloriesChange: 0,
                weeklySteps: Array(repeating: 0, count: 7), monthlySteps: Array(repeating: 0, count: 8),
                dailyStepsChange: 0, weeklyStepsChange: 0, monthlyStepsChange: 0,
                dailyCaloriesChange: 0, weeklyCaloriesChange: 0, monthlyCaloriesChange: 0
            )
        }

        let todaySteps: Int
        let todayCalories: Int

        do {
            todaySteps = try await healthManager.fetchStepCount()
            print("❤️ 오늘 걸음수: \(todaySteps)")
        } catch {
            print("❤️ 걸음수 가져오기 실패: \(error)")
            todaySteps = 0
        }

        do {
            todayCalories = try await healthManager.fetchCalorieCount()
            print("❤️ 오늘 칼로리: \(todayCalories)")
        } catch {
            print("❤️ 칼로리 가져오기 실패: \(error)")
            todayCalories = 0
        }

        let yearlyData: [HealthManager.DailyMetric]
        do {
            yearlyData = try await healthManager.fetchLastYearFromYesterday()
            print("❤️ 과거 데이터 개수: \(yearlyData.count)")
        } catch {
            print("❤️ 과거 데이터 가져오기 실패: \(error)")
            yearlyData = generateMockYearlyData()
        }

        let (weeklySteps, monthlySteps) = calculateStepsData(from: yearlyData)
        let stepsChange = calculateStepsChange(from: yearlyData, current: todaySteps)
        let caloriesChange = calculateCaloriesChange(from: yearlyData, current: todayCalories)

        print("❤️ 계산된 변화율:")
        print("❤️ - 걸음수 변화: \(stepsChange)%")
        print("❤️ - 칼로리 변화: \(caloriesChange)%")

        return ExerciseData(
            averageSteps: todaySteps,
            stepsChange: stepsChange,
            averageCalories: todayCalories,
            caloriesChange: caloriesChange,
            weeklySteps: weeklySteps,
            monthlySteps: monthlySteps,
            dailyStepsChange: calculateDailyStepsChange(from: yearlyData, current: todaySteps),
            weeklyStepsChange: calculateWeeklyStepsChange(from: yearlyData),
            monthlyStepsChange: calculateMonthlyStepsChange(from: yearlyData),
            dailyCaloriesChange: calculateDailyCaloriesChange(from: yearlyData, current: todayCalories),
            weeklyCaloriesChange: calculateWeeklyCaloriesChange(from: yearlyData),
            monthlyCaloriesChange: calculateMonthlyCaloriesChange(from: yearlyData)
        )
    }
    
    private func generateMockYearlyData() -> [HealthManager.DailyMetric] {
        print("❤️ Mock 연간 데이터 생성")
        let calendar = Calendar.current
        var data: [HealthManager.DailyMetric] = []

        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayStart = calendar.startOfDay(for: date)

            let steps = Int.random(in: 3000...12000)
            let kcal = Int.random(in: 200...800)
            let avgHR = Int.random(in: 60...100)
            let sleepMinutes = Int.random(in: 360...540)

            data.append(HealthManager.DailyMetric(
                dayStart: dayStart,
                steps: steps,
                kcal: kcal,
                avgHR: avgHR,
                sleepMinutes: sleepMinutes
            ))
        }

        return data.reversed()
    }
    
    private func calculateCaloriesChange(from yearlyData: [HealthManager.DailyMetric], current: Int) -> Int {
        guard yearlyData.count >= 14 else { return 0 }

        let last7Days = Array(yearlyData.suffix(7))
        let previous7Days = Array(yearlyData.dropLast(7).suffix(7))

        let currentAvg = last7Days.map { $0.kcal }.reduce(0, +) / max(last7Days.count, 1)
        let previousAvg = previous7Days.map { $0.kcal }.reduce(0, +) / max(previous7Days.count, 1)

        guard previousAvg > 0 else { return 0 }

        return Int(((Double(currentAvg) - Double(previousAvg)) / Double(previousAvg)) * 100)
    }
    
    private func calculateStepsChange(from yearlyData: [HealthManager.DailyMetric], current: Int) -> Int {
        guard yearlyData.count >= 14 else { return 0 }

        let last7Days = Array(yearlyData.suffix(7))
        let previous7Days = Array(yearlyData.dropLast(7).suffix(7))

        let currentAvg = last7Days.map { $0.steps }.reduce(0, +) / max(last7Days.count, 1)
        let previousAvg = previous7Days.map { $0.steps }.reduce(0, +) / max(previous7Days.count, 1)

        guard previousAvg > 0 else { return 0 }

        return Int(((Double(currentAvg) - Double(previousAvg)) / Double(previousAvg)) * 100)
    }
    
    func calculateStepsData(from yearlyData: [HealthManager.DailyMetric]) -> ([Double], [Double]) {
        let recent30Days = Array(yearlyData.suffix(30))
        let recent7Days = Array(yearlyData.suffix(7))

        let weeklySteps = recent7Days.map { Double($0.steps) }
        let monthlySteps = stride(from: 0, to: recent30Days.count, by: 4).map { startIndex in
            let endIndex = min(startIndex + 4, recent30Days.count)
            let weekData = Array(recent30Days[startIndex..<endIndex])
            return weekData.map { Double($0.steps) }.reduce(0, +) / Double(max(weekData.count, 1))
        }

        return (weeklySteps, monthlySteps)
    }
    
    private func calculateDailyStepsChange(from yearlyData: [HealthManager.DailyMetric], current: Int) -> Int {
        guard let yesterday = yearlyData.last else { return 0 }
        guard yesterday.steps > 0 else { return 0 }

        let change = (Double(current - yesterday.steps) / Double(yesterday.steps)) * 100
        return Int(change)
    }

    private func calculateWeeklyStepsChange(from yearlyData: [HealthManager.DailyMetric]) -> Int {
        guard yearlyData.count >= 14 else { return 0 }

        let thisWeek = yearlyData.suffix(7)
        let lastWeek = yearlyData.dropLast(7).suffix(7)

        let thisAvg = thisWeek.map { $0.steps }.reduce(0, +) / max(thisWeek.count, 1)
        let lastAvg = lastWeek.map { $0.steps }.reduce(0, +) / max(lastWeek.count, 1)

        guard lastAvg > 0 else { return 0 }

        let change = (Double(thisAvg - lastAvg) / Double(lastAvg)) * 100
        return Int(change)
    }

    private func calculateMonthlyStepsChange(from yearlyData: [HealthManager.DailyMetric]) -> Int {
        guard yearlyData.count >= 60 else { return 0 }

        let thisMonth = yearlyData.suffix(30)
        let lastMonth = yearlyData.dropLast(30).suffix(30)

        let thisAvg = thisMonth.map { $0.steps }.reduce(0, +) / max(thisMonth.count, 1)
        let lastAvg = lastMonth.map { $0.steps }.reduce(0, +) / max(lastMonth.count, 1)

        guard lastAvg > 0 else { return 0 }
        return Int((Double(thisAvg - lastAvg) / Double(lastAvg)) * 100)
    }

    private func calculateDailyCaloriesChange(from yearlyData: [HealthManager.DailyMetric], current: Int) -> Int {
        guard let yesterday = yearlyData.last else { return 0 }
        guard yesterday.kcal > 0 else { return 0 }
        return Int((Double(current - yesterday.kcal) / Double(yesterday.kcal)) * 100)
    }

    private func calculateWeeklyCaloriesChange(from yearlyData: [HealthManager.DailyMetric]) -> Int {
        guard yearlyData.count >= 14 else { return 0 }

        let thisWeek = yearlyData.suffix(7)
        let lastWeek = yearlyData.dropLast(7).suffix(7)

        let thisAvg = thisWeek.map { $0.kcal }.reduce(0, +) / max(thisWeek.count, 1)
        let lastAvg = lastWeek.map { $0.kcal }.reduce(0, +) / max(lastWeek.count, 1)

        guard lastAvg > 0 else { return 0 }
        return Int((Double(thisAvg - lastAvg) / Double(lastAvg)) * 100)
    }

    private func calculateMonthlyCaloriesChange(from yearlyData: [HealthManager.DailyMetric]) -> Int {
        guard yearlyData.count >= 60 else { return 0 }

        let thisMonth = yearlyData.suffix(30)
        let lastMonth = yearlyData.dropLast(30).suffix(30)

        let thisAvg = thisMonth.map { $0.kcal }.reduce(0, +) / max(thisMonth.count, 1)
        let lastAvg = lastMonth.map { $0.kcal }.reduce(0, +) / max(lastMonth.count, 1)

        guard lastAvg > 0 else { return 0 }
        return Int((Double(thisAvg - lastAvg) / Double(lastAvg)) * 100)
    }
}
