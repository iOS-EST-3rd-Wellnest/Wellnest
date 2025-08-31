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
class AnalyticsViewModel: ObservableObject {
    @Published var healthData: HealthData
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasRealData: Bool = false

    private let healthManager = HealthManager.shared
    
    static let defaultExerciseData = ExerciseData(
        averageSteps: 8500,            // 하루 평균 8,500보
        stepsChange: 300,             // 전일 대비 +300보
        averageCalories: 2100,        // 하루 평균 2,100kcal
        caloriesChange: -150,         // 전일 대비 -150kcal
        weeklySteps: [8200, 8700, 7600, 9100, 10000, 9500, 8800], // 최근 7일
        monthlySteps: [
            8300, 8700, 7900, 9200, 8500, 9100, 8800, 9600, 10000, 10200,
            7700, 8400, 8900, 9100, 9300, 9500, 9700, 8800, 8200, 9400,
            8600, 8700, 9100, 8900, 9300, 9600, 9800, 10100, 9500, 8700
        ], // 최근 한 달치
        dailyStepsChange: 4,          // 어제보다 4% 증가
        weeklyStepsChange: 6,         // 지난주 대비 6% 증가
        monthlyStepsChange: -2,       // 지난달 대비 2% 감소
        dailyCaloriesChange: -5,      // 어제보다 5% 감소
        weeklyCaloriesChange: 3,      // 지난주 대비 3% 증가
        monthlyCaloriesChange: 1,     // 지난달 대비 1% 증가
        hasStepsData: false,
        hasCaloriesData: false,
        isHealthKitConnected: false
    )
    
    private static let deaultSleepData = SleepData(
        averageHours: 7.3,       // 7시간 18분
        averageMinutes: 10,     // 분 단위
        sleepQuality: 75,        // 수면 질 점수 (0~100 가정)
        qualityChange: 3,        // 전일 대비 +3%
        
        weeklySleepHours: [6.8, 7.2, 6.5, 7.0, 7.4, 8.1, 8.0 ], // 최근 7일 (평일/주말 차이 반영)
        monthlySleepHours: [6.9, 7.1, 7.0, 6.8, 7.5, 8.0, 7.9,
                            6.7, 7.3, 7.2, 6.9, 7.4, 7.8, 8.1,
                            6.6, 7.0, 7.3, 6.8, 7.2, 7.6, 8.0,
                            6.9, 7.1, 7.4, 7.2, 7.5, 8.2, 7.8,
                            6.8, 7.3], // 최근 30일
        
        dailySleepTimeChange: 2,     // 전일 대비 2% 증가
        weeklySleepTimeChange: -1,   // 지난주 대비 1% 감소
        monthlySleepTimeChange: 0,   // 지난달과 비슷
        dailyQualityChange: 1,       // 전일 대비 +1%
        weeklyQualityChange: -2,     // 지난주 대비 -2%
        monthlyQualityChange: 3,     // 지난달 대비 +3%
        hasSleepTimeData: false,
        hasSleepQualityData: false,
        isHealthKitConnected: false
    )

    init() {
        self.healthData = HealthData(
            userName: "사용자",
            aiInsight: AIInsightData(message: "데이터를 불러오는 중..."),
            exercise: Self.defaultExerciseData,
            sleep: Self.deaultSleepData,
        )

        Task {
            await loadHealthData()
        }
    }

    private func loadHealthData() async {
        isLoading = true
        errorMessage = nil

        print("건강 데이터 로드 시작")

        let userName = getUserName()

        async let exerciseData = loadExerciseData()
        async let sleepData = loadSleepData()

        let (exercise, sleep) = await (
            exerciseData, sleepData
        )

        print("로드된 데이터:")
        print("- 걸음수: \(exercise.averageSteps)")
        print("- 칼로리: \(exercise.averageCalories)")
        print("- 수면시간: \(sleep.averageHours)시간 \(sleep.averageMinutes)분")
        print("- 수면 품질: \(sleep.sleepQuality)%")

        let aiInsight = generateAIInsight(
            exercise: exercise,
            sleep: sleep,
            hasRealData: self.hasRealData
        )

        await MainActor.run {
            self.healthData = HealthData(
                userName: userName,
                aiInsight: aiInsight,
                exercise: exercise,
                sleep: sleep,
            )
            
            self.isLoading = false
        }
    }

    private func loadExerciseData() async -> ExerciseData {
        guard HKHealthStore.isHealthDataAvailable() else {
            return Self.defaultExerciseData
        }

        let authCheck = await healthManager.finalAuthSnapshot()
        
        // Exercise 관련 권한 확인
        let stepTypeId = HKQuantityTypeIdentifier.stepCount.rawValue
        let calorieTypeId = HKQuantityTypeIdentifier.activeEnergyBurned.rawValue
        
        let missingExerciseTypes = authCheck.missingCore.filter { type in
            let identifier = type.identifier
            return identifier == stepTypeId || identifier == calorieTypeId
        }
        
        let isHealthKitConnected = missingExerciseTypes.count < 2 // 둘 중 하나라도 있으면 연동됨
        
        var hasStepsData = false
        var hasCaloriesData = false
        let todaySteps: Int
        let todayCalories: Int

        do {
            todaySteps = try await healthManager.fetchStepCount()
            if todaySteps > 100 {
                hasStepsData = true
                self.hasRealData = true
            }
        } catch {
            todaySteps = Self.defaultExerciseData.averageSteps
        }

        do {
            todayCalories = try await healthManager.fetchCalorieCount()
            if todayCalories > 10 {
                hasCaloriesData = true
                self.hasRealData = true
            }
        } catch {
            todayCalories = Self.defaultExerciseData.averageCalories
        }

        let yearlyData: [HealthManager.DailyMetric]
        do {
            yearlyData = try await healthManager.fetchLastYearFromYesterday()
            print("과거 데이터 개수: \(yearlyData.count)")
        } catch {
            print("과거 데이터 가져오기 실패: \(error)")
            yearlyData = generateMockYearlyData()
        }

        let (weeklySteps, monthlySteps) = calculateStepsData(from: yearlyData)
        let stepsChange = calculateStepsChange(from: yearlyData, current: todaySteps)
        let caloriesChange = calculateCaloriesChange(from: yearlyData, current: todayCalories)

        return ExerciseData(
            averageSteps: hasStepsData ? todaySteps : Self.defaultExerciseData.averageSteps,
            stepsChange: hasStepsData ? stepsChange : Self.defaultExerciseData.stepsChange,
            averageCalories: hasCaloriesData ? todayCalories : Self.defaultExerciseData.averageCalories,
            caloriesChange: hasCaloriesData ? caloriesChange : Self.defaultExerciseData.caloriesChange,
            weeklySteps: hasStepsData ? weeklySteps : Self.defaultExerciseData.weeklySteps,
            monthlySteps: hasStepsData ? monthlySteps : Self.defaultExerciseData.monthlySteps,
            dailyStepsChange: hasStepsData ? calculateDailyStepsChange(from: yearlyData, current: todaySteps) : Self.defaultExerciseData.dailyStepsChange,
            weeklyStepsChange: hasStepsData ? calculateWeeklyStepsChange(from: yearlyData) : Self.defaultExerciseData.weeklyStepsChange,
            monthlyStepsChange: hasStepsData ? calculateMonthlyStepsChange(from: yearlyData) : Self.defaultExerciseData.monthlyStepsChange,
            dailyCaloriesChange: hasCaloriesData ? calculateDailyCaloriesChange(from: yearlyData, current: todayCalories) : Self.defaultExerciseData.dailyCaloriesChange,
            weeklyCaloriesChange: hasCaloriesData ? calculateWeeklyCaloriesChange(from: yearlyData) : Self.defaultExerciseData.weeklyCaloriesChange,
            monthlyCaloriesChange: hasCaloriesData ? calculateMonthlyCaloriesChange(from: yearlyData) : Self.defaultExerciseData.monthlyCaloriesChange,
            hasStepsData: hasStepsData,
            hasCaloriesData: hasCaloriesData,
            isHealthKitConnected: isHealthKitConnected
        )
    }

    private func loadSleepData() async -> SleepData {
        print("수면 데이터 로드 시작")

        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit을 사용할 수 없음")
            return Self.deaultSleepData
        }

        let authCheck = await healthManager.finalAuthSnapshot()

        // Sleep 관련 권한 확인 (더 직접적인 방법)
        let sleepTypeId = HKCategoryTypeIdentifier.sleepAnalysis.rawValue
        
        let missingSleepTypes = authCheck.missingCore.filter { type in
            type.identifier == sleepTypeId
        }
        
        let isHealthKitConnected = missingSleepTypes.isEmpty // 수면 권한이 있으면 연동됨
        var hasSleepTimeData = false
        var hasSleepQualityData = false
        let sleepDuration: TimeInterval
        
        do {
            sleepDuration = try await healthManager.fetchSleepDuration()
            if sleepDuration >= 3600 {
                hasSleepTimeData = true
                hasSleepQualityData = true
                self.hasRealData = true
            }
        } catch {
            sleepDuration = Self.deaultSleepData.defaultSleepDuration
        }

        let hours = sleepDuration / 3600
        let minutes = Int((sleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)

        if sleepDuration >= 7200 {
            self.hasRealData = true
            print("실제 수면 데이터 발견")
        }

        let yearlyData: [HealthManager.DailyMetric]
        do {
            yearlyData = try await healthManager.fetchLastYearFromYesterday()
            print("수면 과거 데이터 개수: \(yearlyData.count)")
        } catch {
            print("수면 과거 데이터 가져오기 실패: \(error)")
            yearlyData = generateMockYearlyData()
        }

        let (weeklySleep, monthlySleep) = calculateSleepData(from: yearlyData)
        let sleepQuality = calculateSleepQuality(hours: hours)
        let qualityChange = calculateSleepQualityChange(from: yearlyData, currentHours: hours)

        return SleepData(
            averageHours: hasSleepTimeData ? hours : Self.deaultSleepData.averageHours,
            averageMinutes: hasSleepTimeData ? minutes : Self.deaultSleepData.averageMinutes,
            sleepQuality: hasSleepQualityData ? sleepQuality : Self.deaultSleepData.sleepQuality,
            qualityChange: hasSleepQualityData ? qualityChange : Self.deaultSleepData.qualityChange,
            weeklySleepHours: hasSleepTimeData ? weeklySleep : Self.deaultSleepData.weeklySleepHours,
            monthlySleepHours: hasSleepTimeData ? monthlySleep : Self.deaultSleepData.monthlySleepHours,
            dailySleepTimeChange: hasSleepTimeData ? calculateDailySleepTimeChange(from: yearlyData, current: hours) : Self.deaultSleepData.dailySleepTimeChange,
            weeklySleepTimeChange: hasSleepTimeData ? calculateWeeklySleepTimeChange(from: yearlyData) : Self.deaultSleepData.weeklySleepTimeChange,
            monthlySleepTimeChange: hasSleepTimeData ? calculateMonthlySleepTimeChange(from: yearlyData) : Self.deaultSleepData.monthlySleepTimeChange,
            dailyQualityChange: hasSleepQualityData ? calculateDailySleepQualityChange(from: yearlyData, current: sleepQuality) : Self.deaultSleepData.dailyQualityChange,
            weeklyQualityChange: hasSleepQualityData ? calculateWeeklySleepQualityChange(from: yearlyData) : Self.deaultSleepData.weeklyQualityChange,
            monthlyQualityChange: hasSleepQualityData ? calculateMonthlySleepQualityChange(from: yearlyData) : Self.deaultSleepData.monthlyQualityChange,
            hasSleepTimeData: hasSleepTimeData,
            hasSleepQualityData: hasSleepQualityData,
            isHealthKitConnected: isHealthKitConnected
        )
    }

    private func generateAIInsight(
//        planCompletion: PlanCompletionData,
        exercise: ExerciseData,
        sleep: SleepData,
        hasRealData: Bool
    ) -> AIInsightData {

        print("AI 인사이트 생성 중...")
//        print("- 일정: \(planCompletion.completedItems)/\(planCompletion.totalItems)")
        print("- 걸음수: \(exercise.averageSteps)")
        print("- 수면: \(sleep.averageHours)시간")
        print("- hasRealData: \(hasRealData)")

//        if planCompletion.totalItems == 0 {
//            print("일정이 없음 - 일정 추가 권유")
//            return AIInsightData(message: "오늘 일정을 추가해보세요. 체계적인 관리가 건강의 시작이에요!")
//        }

        if !hasRealData {
            print("실제 데이터 없음 - 대기 메시지")
            return AIInsightData(message: "활동을 시작하면 맞춤 분석을 제공해드릴게요!")
        }

        var insights: [String] = []

//        let completionRate = planCompletion.completionRate
//        if completionRate >= 0.8 {
//            insights.append("오늘 계획을 \(Int(completionRate * 100))% 달성했어요! 훌륭해요")
//        } else if completionRate >= 0.5 {
//            insights.append("오늘 계획을 절반 이상 완료했어요. 조금만 더 힘내세요!")
//        } else if planCompletion.totalItems > 0 {
//            let remaining = planCompletion.totalItems - planCompletion.completedItems
//            if remaining == 1 {
//                insights.append("오늘 1개 일정이 남았어요. 마지막 스퍼트!")
//            } else {
//                insights.append("오늘 \(remaining)개 일정이 남았어요. 하나씩 차근차근 해보세요!")
//            }
//        }

        if exercise.averageSteps >= 10000 {
            insights.append("오늘 \(formatSteps(exercise.averageSteps))를 걸었어요. 목표 달성!")
        } else if exercise.averageSteps >= 8000 {
            insights.append("오늘 \(formatSteps(exercise.averageSteps))를 걸었어요. 건강한 하루네요!")
        } else if exercise.averageSteps >= 5000 {
            insights.append("오늘 \(formatSteps(exercise.averageSteps))를 걸었어요. 조금만 더 걸어볼까요?")
        } else if exercise.averageSteps > 1000 {
            insights.append("오늘 \(formatSteps(exercise.averageSteps))를 걸었어요. 좋은 시작이에요!")
        } else if exercise.averageSteps > 0 {
            insights.append("걸음수를 늘려보세요. 작은 산책도 좋은 시작이에요!")
        }

        if sleep.averageHours >= 7 && sleep.averageHours <= 9 {
            insights.append("충분한 수면으로 컨디션이 좋을 것 같아요")
        } else if sleep.averageHours > 0 && sleep.averageHours < 7 {
            insights.append("수면이 부족해 보여요. 오늘은 일찍 잠자리에 들어보세요")
        } else if sleep.averageHours > 9 {
            insights.append("충분히 잠을 잤네요. 활기찬 하루 되세요!")
        }

        if exercise.stepsChange > 15 && sleep.sleepQuality >= 80 {
            insights.append("운동량 증가로 수면 질도 좋아졌어요!")
        } else if exercise.stepsChange > 20 {
            insights.append("이전보다 \(exercise.stepsChange)% 더 활동적이에요. 멋져요!")
        }

        if insights.isEmpty {
            let defaultInsights = [
                "꾸준한 건강 관리가 중요해요. 오늘도 화이팅!",
                "작은 변화가 큰 차이를 만들어요",
                "건강한 습관을 하나씩 만들어가고 있어요",
                "데이터가 쌓일수록 더 정확한 분석을 제공할게요",
                "오늘도 건강을 위한 한 걸음을 내디뎌보세요"
            ]
            insights = defaultInsights
        }

        let selectedInsight = insights.randomElement() ?? insights[0]
        print("생성된 AI 인사이트: \(selectedInsight)")

        return AIInsightData(message: selectedInsight)
    }

    private func formatSteps(_ steps: Int) -> String {
        if steps >= 10000 {
            return "\(String(format: "%.1f", Double(steps) / 1000))천보"
        } else if steps >= 1000 {
            return "\(String(format: "%.1f", Double(steps) / 1000))천보"
        } else {
            return "\(steps)보"
        }
    }

    private func calculateStepsData(from yearlyData: [HealthManager.DailyMetric]) -> ([Double], [Double]) {
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

    private func calculateSleepData(from yearlyData: [HealthManager.DailyMetric]) -> ([Double], [Double]) {
        let recent30Days = Array(yearlyData.suffix(30))
        let recent7Days = Array(yearlyData.suffix(7))

        let weeklySleep = recent7Days.map { Double($0.sleepMinutes) / 60.0 }
        let monthlySleep = stride(from: 0, to: recent30Days.count, by: 4).map { startIndex in
            let endIndex = min(startIndex + 4, recent30Days.count)
            let weekData = Array(recent30Days[startIndex..<endIndex])
            return weekData.map { Double($0.sleepMinutes) / 60.0 }.reduce(0, +) / Double(max(weekData.count, 1))
        }

        return (weeklySleep, monthlySleep)
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

    private func calculateCaloriesChange(from yearlyData: [HealthManager.DailyMetric], current: Int) -> Int {
        guard yearlyData.count >= 14 else { return 0 }

        let last7Days = Array(yearlyData.suffix(7))
        let previous7Days = Array(yearlyData.dropLast(7).suffix(7))

        let currentAvg = last7Days.map { $0.kcal }.reduce(0, +) / max(last7Days.count, 1)
        let previousAvg = previous7Days.map { $0.kcal }.reduce(0, +) / max(previous7Days.count, 1)

        guard previousAvg > 0 else { return 0 }

        return Int(((Double(currentAvg) - Double(previousAvg)) / Double(previousAvg)) * 100)
    }

    private func calculateSleepQuality(hours: Double) -> Int {
        switch hours {
        case 7...9:
            return 100
        case 6..<7:
            return Int(70 + (hours - 6) * 30)
        case 9..<10:
            return Int(100 - (hours - 9) * 20)
        case 5..<6:
            return Int(40 + (hours - 5) * 30)
        case 10..<11:
            return Int(60 - (hours - 10) * 20)
        default:
            return max(20, Int(40 - abs(hours - 7.5) * 10))
        }
    }

    private func calculateSleepQualityChange(from yearlyData: [HealthManager.DailyMetric], currentHours: Double) -> Int {
        guard yearlyData.count >= 14 else { return 0 }

        let last7Days = Array(yearlyData.suffix(7))
        let previous7Days = Array(yearlyData.dropLast(7).suffix(7))

        let currentQuality = last7Days.map { calculateSleepQuality(hours: Double($0.sleepMinutes) / 60.0) }.reduce(0, +) / max(last7Days.count, 1)
        let previousQuality = previous7Days.map { calculateSleepQuality(hours: Double($0.sleepMinutes) / 60.0) }.reduce(0, +) / max(previous7Days.count, 1)

        return currentQuality - previousQuality
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

    private func calculateDailySleepTimeChange(from yearlyData: [HealthManager.DailyMetric], current: Double) -> Int {
        guard let yesterday = yearlyData.last else { return 0 }
        let yesterdayHours = Double(yesterday.sleepMinutes) / 60.0
        guard yesterdayHours > 0 else { return 0 }
        return Int((current - yesterdayHours) / yesterdayHours * 100)
    }

    private func calculateWeeklySleepTimeChange(from yearlyData: [HealthManager.DailyMetric]) -> Int {
        guard yearlyData.count >= 14 else { return 0 }

        let thisWeek = yearlyData.suffix(7)
        let lastWeek = yearlyData.dropLast(7).suffix(7)

        let thisAvg = thisWeek.map { Double($0.sleepMinutes) }.reduce(0, +) / Double(max(thisWeek.count, 1)) / 60.0
        let lastAvg = lastWeek.map { Double($0.sleepMinutes) }.reduce(0, +) / Double(max(lastWeek.count, 1)) / 60.0

        guard lastAvg > 0 else { return 0 }
        return Int((thisAvg - lastAvg) / lastAvg * 100)
    }

    private func calculateMonthlySleepTimeChange(from yearlyData: [HealthManager.DailyMetric]) -> Int {
        guard yearlyData.count >= 60 else { return 0 }

        let thisMonth = yearlyData.suffix(30)
        let lastMonth = yearlyData.dropLast(30).suffix(30)

        let thisAvg = thisMonth.map { Double($0.sleepMinutes) }.reduce(0, +) / Double(max(thisMonth.count, 1)) / 60.0
        let lastAvg = lastMonth.map { Double($0.sleepMinutes) }.reduce(0, +) / Double(max(lastMonth.count, 1)) / 60.0

        guard lastAvg > 0 else { return 0 }
        return Int((thisAvg - lastAvg) / lastAvg * 100)
    }

    private func calculateDailySleepQualityChange(from yearlyData: [HealthManager.DailyMetric], current: Int) -> Int {
        guard let yesterday = yearlyData.last else { return 0 }
        let yesterdayHours = Double(yesterday.sleepMinutes) / 60.0
        let yesterdayQuality = calculateSleepQuality(hours: yesterdayHours)
        guard yesterdayQuality > 0 else { return 0 }
        return current - yesterdayQuality
    }

    private func calculateWeeklySleepQualityChange(from yearlyData: [HealthManager.DailyMetric]) -> Int {
        guard yearlyData.count >= 14 else { return 0 }

        let thisWeek = yearlyData.suffix(7)
        let lastWeek = yearlyData.dropLast(7).suffix(7)

        let thisAvg = thisWeek.map { calculateSleepQuality(hours: Double($0.sleepMinutes) / 60.0) }.reduce(0, +) / max(thisWeek.count, 1)
        let lastAvg = lastWeek.map { calculateSleepQuality(hours: Double($0.sleepMinutes) / 60.0) }.reduce(0, +) / max(lastWeek.count, 1)

        return thisAvg - lastAvg
    }

    private func calculateMonthlySleepQualityChange(from yearlyData: [HealthManager.DailyMetric]) -> Int {
        guard yearlyData.count >= 60 else { return 0 }

        let thisMonth = yearlyData.suffix(30)
        let lastMonth = yearlyData.dropLast(30).suffix(30)

        let thisAvg = thisMonth.map { calculateSleepQuality(hours: Double($0.sleepMinutes) / 60.0) }.reduce(0, +) / max(thisMonth.count, 1)
        let lastAvg = lastMonth.map { calculateSleepQuality(hours: Double($0.sleepMinutes) / 60.0) }.reduce(0, +) / max(lastMonth.count, 1)

        return thisAvg - lastAvg
    }

    private func generateMockYearlyData() -> [HealthManager.DailyMetric] {
        print("Mock 연간 데이터 생성")
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

    func getUserName() -> String {
        let coreDataService = CoreDataService.shared

        do {
            let userRequest = NSFetchRequest<NSManagedObject>(entityName: "UserEntity")
            userRequest.fetchLimit = 1

            let users = try coreDataService.context.fetch(userRequest)

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

    func refreshData() async {
        print("수동 새로고침 시작")
        await loadHealthData()
    }
}
