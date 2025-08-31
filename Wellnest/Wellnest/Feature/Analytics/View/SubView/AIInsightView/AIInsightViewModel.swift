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
    
    init() {
        Task { await loadAIInsight() }
    }
    
    func loadAIInsight() async {
        let healthData = try? await loadExerciseData()
        let result = await fetchAIInsight(input: healthData)
//        let result = await fetchAIInsight(input: nil)
        
        await MainActor.run {
            self.insightText = result
        }
    }
}

private extension AIInsightViewModel {
    func fetchAIInsight(input: ExerciseData?) async -> AttributedString? {
        do {
            let aiService = AIServiceProxy()
            let result = try await aiService.request(prompt: Self.insightPrompt(input: input))
            
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
    
    static func insightPrompt(input: ExerciseData?) -> String {
        return """
                \(input?.AIPrompt ?? "건강 데이터가 없음")
                
                위 데이터를 참조해서 내가 오늘 어떻게 건강관리를 하면 좋을지 40자 제한, 한 문장으로 만들어줘.
                응원하는 얘기도 좋아. 만약 데이터가 없으면 니가 추천해 주고 싶은 건강관리 말을 만들어줘.
                
                응답은 반드시 다음 JSON 형식으로 해줘:
                {"sentence": "여기에 건강관리 문장"}
                """
    }
}

private extension ExerciseData {
    var AIPrompt: String {
     return """
         운동 데이터 AI 프롬프트
         사용자 운동 데이터:
         - 하루 평균 걸음 수: \(averageSteps)보
         - 걸음 수 변화량: \(stepsChange)
         - 하루 평균 칼로리 소모: \(averageCalories)kcal
         - 칼로리 변화량: \(caloriesChange)
         - 주간 걸음 수 데이터: \(weeklySteps)
         - 월간 걸음 수 데이터: \(monthlySteps)
         변화율 데이터:
         - 일일 걸음 수 변화율: \(dailyStepsChange)%
         - 주간 걸음 수 변화율: \(weeklyStepsChange)%
         - 월간 걸음 수 변화율: \(monthlyStepsChange)%
         - 일일 칼로리 변화율: \(dailyCaloriesChange)%
         - 주간 칼로리 변화율: \(weeklyCaloriesChange)%
         - 월간 칼로리 변화율: \(monthlyCaloriesChange)%
         """
    }
}

    
private extension AIInsightViewModel {
    func loadExerciseData() async throws -> ExerciseData {

        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let healthManager = await MainActor.run { HealthManager.shared }
        let authCheck = await healthManager.finalAuthSnapshot()
        if !authCheck.missingCore.isEmpty {
            throw HealthKitError.notAvailable
        }

        let todaySteps: Int
        let todayCalories: Int

        do {
            todaySteps = try await healthManager.fetchStepCount()
        } catch {
            throw HealthKitError.notAvailable
        }

        do {
            todayCalories = try await healthManager.fetchCalorieCount()
        } catch {
            throw HealthKitError.notAvailable
        }

        let yearlyData: [HealthManager.DailyMetric]
        do {
            yearlyData = try await healthManager.fetchLastYearFromYesterday()
        } catch {
            yearlyData = generateMockYearlyData()
        }

        let (weeklySteps, monthlySteps) = calculateStepsData(from: yearlyData)
        let stepsChange = calculateStepsChange(from: yearlyData, current: todaySteps)
        let caloriesChange = calculateCaloriesChange(from: yearlyData, current: todayCalories)


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
            monthlyCaloriesChange: calculateMonthlyCaloriesChange(from: yearlyData),
            hasStepsData: true,
            hasCaloriesData: true,
            isHealthKitConnected: true
        )
    }
    
    private func generateMockYearlyData() -> [HealthManager.DailyMetric] {
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
