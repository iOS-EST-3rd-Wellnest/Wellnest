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
    private let coreDataStore = CoreDataStore()

    init() {
        self.healthData = HealthData(
            userName: "사용자",
            planCompletion: PlanCompletionData(completedItems: 0, totalItems: 0),
            aiInsight: AIInsightData(message: "데이터를 불러오는 중..."),
            exercise: ExerciseData(
                averageSteps: 0,
                stepsChange: 0,
                averageCalories: 0,
                caloriesChange: 0,
                weeklySteps: Array(repeating: 0, count: 7),
                monthlySteps: Array(repeating: 0, count: 8),
                dailyStepsChange: 0,
                weeklyStepsChange: 0,
                monthlyStepsChange: 0,
                dailyCaloriesChange: 0,
                weeklyCaloriesChange: 0,
                monthlyCaloriesChange: 0
            ),
            sleep: SleepData(
                averageHours: 0,
                averageMinutes: 0,
                sleepQuality: 0,
                qualityChange: 0,
                weeklySleepHours: Array(repeating: 0, count: 7),
                monthlySleepHours: Array(repeating: 0, count: 8),
                dailySleepTimeChange: 0,
                weeklySleepTimeChange: 0,
                monthlySleepTimeChange: 0,
                dailyQualityChange: 0,
                weeklyQualityChange: 0,
                monthlyQualityChange: 0
            ),
            meditation: MeditationData(weeklyCount: 0, changeCount: 0)
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

        async let planData = loadPlanCompletionData()
        async let exerciseData = loadExerciseData()
        async let sleepData = loadSleepData()
        async let meditationData = loadMeditationData()

        let (plan, exercise, sleep, meditation) = await (
            planData, exerciseData, sleepData, meditationData
        )

        print("로드된 데이터:")
        print("- 일정: \(plan.completedItems)/\(plan.totalItems)")
        print("- 걸음수: \(exercise.averageSteps)")
        print("- 칼로리: \(exercise.averageCalories)")
        print("- 수면시간: \(sleep.averageHours)시간 \(sleep.averageMinutes)분")
        print("- 수면 품질: \(sleep.sleepQuality)%")

        let aiInsight = generateAIInsight(
            planCompletion: plan,
            exercise: exercise,
            sleep: sleep,
            meditation: meditation,
            hasRealData: self.hasRealData
        )

        self.healthData = HealthData(
            userName: userName,
            planCompletion: plan,
            aiInsight: aiInsight,
            exercise: exercise,
            sleep: sleep,
            meditation: meditation
        )

        print("건강 데이터 로드 완료 - UI 업데이트됨")
        isLoading = false
    }

    private func loadPlanCompletionData() async -> PlanCompletionData {
        let coreDataService = CoreDataService.shared
        let model = coreDataService.context.persistentStoreCoordinator?.managedObjectModel
        let entityNames = model?.entities.map { $0.name ?? "Unknown" } ?? []

        print("사용 가능한 CoreData 엔터티: \(entityNames)")

        guard entityNames.contains("ScheduleEntity") else {
            print("ScheduleEntity 엔터티가 없음. 기본 데이터 사용")
            return PlanCompletionData(completedItems: 0, totalItems: 0)
        }

        do {
            let explorationRequest = NSFetchRequest<NSManagedObject>(entityName: "ScheduleEntity")
            explorationRequest.fetchLimit = 5

            let sampleActivities = try coreDataService.context.fetch(explorationRequest)
            print("ScheduleEntity 샘플 개수: \(sampleActivities.count)")

            if sampleActivities.isEmpty {
                print("일정이 없음. 0/0 반환")
                return PlanCompletionData(completedItems: 0, totalItems: 0)
            }

            var dateAttributeName: String?
            var completedAttributeName: String?

            if let firstActivity = sampleActivities.first {
                let entity = firstActivity.entity
                let attributeNames = entity.attributesByName.keys.sorted()
                print("ScheduleEntity 속성들: \(attributeNames)")

                let possibleDateFields = ["date", "scheduledDate", "startDate", "createdAt", "dateTime"]
                for dateField in possibleDateFields {
                    if attributeNames.contains(dateField) {
                        dateAttributeName = dateField
                        print("날짜 속성 발견: \(dateField)")
                        break
                    }
                }

                let possibleCompletedFields = ["isCompleted", "completed", "isDone", "finished", "status"]
                for completedField in possibleCompletedFields {
                    if attributeNames.contains(completedField) {
                        completedAttributeName = completedField
                        print("완료 상태 속성 발견: \(completedField)")
                        break
                    }
                }
            }

            var todayActivities: [NSManagedObject] = []

            if let dateAttr = dateAttributeName {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

                let todayRequest = NSFetchRequest<NSManagedObject>(entityName: "ScheduleEntity")
                todayRequest.predicate = NSPredicate(
                    format: "%K >= %@ AND %K < %@",
                    dateAttr, today as NSDate,
                    dateAttr, tomorrow as NSDate
                )
                todayRequest.sortDescriptors = [NSSortDescriptor(key: dateAttr, ascending: true)]

                todayActivities = try coreDataService.context.fetch(todayRequest)
                print("오늘 일정 개수: \(todayActivities.count)")
            } else {
                todayActivities = sampleActivities
                print("전체 일정 개수: \(todayActivities.count)")
            }

            if todayActivities.isEmpty {
                print("오늘 일정이 없음. 0/0 반환")
                return PlanCompletionData(completedItems: 0, totalItems: 0)
            }

            let totalItems = todayActivities.count
            var completedItems = 0

            if let completedAttr = completedAttributeName {
                for activity in todayActivities {
                    if let isCompleted = activity.value(forKey: completedAttr) as? Bool, isCompleted {
                        completedItems += 1
                    } else if let status = activity.value(forKey: completedAttr) as? String,
                              status.lowercased().contains("complete") || status.lowercased().contains("done") {
                        completedItems += 1
                    }
                }
                print("완료된 일정: \(completedItems)/\(totalItems)")
            } else {
                completedItems = 0
                print("완료 상태 속성이 없음: 0/\(totalItems)")
            }

            if totalItems > 0 {
                self.hasRealData = true
            }

            return PlanCompletionData(
                completedItems: completedItems,
                totalItems: totalItems
            )

        } catch {
            print("플랜 데이터 로드 오류: \(error)")
            return PlanCompletionData(completedItems: 0, totalItems: 0)
        }
    }

    private func loadExerciseData() async -> ExerciseData {
        print("운동 데이터 로드 시작")

        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit을 사용할 수 없음")
            return ExerciseData(
                averageSteps: 0, stepsChange: 0, averageCalories: 0, caloriesChange: 0,
                weeklySteps: Array(repeating: 0, count: 7), monthlySteps: Array(repeating: 0, count: 8),
                dailyStepsChange: 0, weeklyStepsChange: 0, monthlyStepsChange: 0,
                dailyCaloriesChange: 0, weeklyCaloriesChange: 0, monthlyCaloriesChange: 0
            )
        }

        let authCheck = await healthManager.finalAuthSnapshot()
        print("HealthKit 권한 상태:")
        print("- 누락된 권한: \(authCheck.missingCore)")

        if !authCheck.missingCore.isEmpty {
            print("HealthKit 권한이 없어서 빈 데이터 반환")
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
            print("오늘 걸음수: \(todaySteps)")
        } catch {
            print("걸음수 가져오기 실패: \(error)")
            todaySteps = 0
        }

        do {
            todayCalories = try await healthManager.fetchCalorieCount()
            print("오늘 칼로리: \(todayCalories)")
        } catch {
            print("칼로리 가져오기 실패: \(error)")
            todayCalories = 0
        }

        if todaySteps > 100 || todayCalories > 10 {
            self.hasRealData = true
            print("실제 운동 데이터 발견")
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

        print("계산된 변화율:")
        print("- 걸음수 변화: \(stepsChange)%")
        print("- 칼로리 변화: \(caloriesChange)%")

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

    private func loadSleepData() async -> SleepData {
        print("수면 데이터 로드 시작")

        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit을 사용할 수 없음")
            return SleepData(
                averageHours: 0, averageMinutes: 0, sleepQuality: 0, qualityChange: 0,
                weeklySleepHours: Array(repeating: 0, count: 7), monthlySleepHours: Array(repeating: 0, count: 8),
                dailySleepTimeChange: 0, weeklySleepTimeChange: 0, monthlySleepTimeChange: 0,
                dailyQualityChange: 0, weeklyQualityChange: 0, monthlyQualityChange: 0
            )
        }

        let authCheck = await healthManager.finalAuthSnapshot()
        if !authCheck.missingCore.isEmpty {
            print("HealthKit 권한이 없어서 빈 데이터 반환")
            return SleepData(
                averageHours: 0, averageMinutes: 0, sleepQuality: 0, qualityChange: 0,
                weeklySleepHours: Array(repeating: 0, count: 7), monthlySleepHours: Array(repeating: 0, count: 8),
                dailySleepTimeChange: 0, weeklySleepTimeChange: 0, monthlySleepTimeChange: 0,
                dailyQualityChange: 0, weeklyQualityChange: 0, monthlyQualityChange: 0
            )
        }

        let sleepDuration: TimeInterval
        do {
            sleepDuration = try await healthManager.fetchSleepDuration()
            print("수면 시간: \(sleepDuration)초 (약 \(sleepDuration/3600)시간)")
        } catch {
            print("수면 시간 가져오기 실패: \(error)")
            sleepDuration = 0
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

        print("계산된 수면 데이터:")
        print("- 수면 품질: \(sleepQuality)%")
        print("- 품질 변화: \(qualityChange)%")

        return SleepData(
            averageHours: hours,
            averageMinutes: minutes,
            sleepQuality: sleepQuality,
            qualityChange: qualityChange,
            weeklySleepHours: weeklySleep,
            monthlySleepHours: monthlySleep,
            dailySleepTimeChange: calculateDailySleepTimeChange(from: yearlyData, current: hours),
            weeklySleepTimeChange: calculateWeeklySleepTimeChange(from: yearlyData),
            monthlySleepTimeChange: calculateMonthlySleepTimeChange(from: yearlyData),
            dailyQualityChange: calculateDailySleepQualityChange(from: yearlyData, current: sleepQuality),
            weeklyQualityChange: calculateWeeklySleepQualityChange(from: yearlyData),
            monthlyQualityChange: calculateMonthlySleepQualityChange(from: yearlyData)
        )
    }

    private func loadMeditationData() async -> MeditationData {
        print("명상 데이터 로드 시작")

        let coreDataService = CoreDataService.shared
        let model = coreDataService.context.persistentStoreCoordinator?.managedObjectModel
        let entityNames = model?.entities.map { $0.name ?? "Unknown" } ?? []

        guard entityNames.contains("ScheduledActivity") else {
            print("ScheduledActivity 엔터티가 없음. 기본 데이터 사용")
            return MeditationData(weeklyCount: 0, changeCount: 0)
        }

        do {
            let calendar = Calendar.current
            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!

            let weekRequest = NSFetchRequest<NSManagedObject>(entityName: "ScheduledActivity")
            weekRequest.predicate = NSPredicate(
                format: "completedAt >= %@ AND completedAt <= %@ AND (title CONTAINS[c] '명상' OR category CONTAINS[c] '명상')",
                weekAgo as NSDate,
                now as NSDate
            )
            weekRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]

            let weekActivities = try coreDataService.context.fetch(weekRequest)
            let weeklyCount = weekActivities.filter { activity in
                return (activity.value(forKey: "isCompleted") as? Bool) ?? false
            }.count

            print("이번 주 명상 횟수: \(weeklyCount)")

            let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now)!
            let previousWeekRequest = NSFetchRequest<NSManagedObject>(entityName: "ScheduledActivity")
            previousWeekRequest.predicate = NSPredicate(
                format: "completedAt >= %@ AND completedAt < %@ AND (title CONTAINS[c] '명상' OR category CONTAINS[c] '명상')",
                twoWeeksAgo as NSDate,
                weekAgo as NSDate
            )

            let previousWeekActivities = try coreDataService.context.fetch(previousWeekRequest)
            let previousWeekCount = previousWeekActivities.filter { activity in
                return (activity.value(forKey: "isCompleted") as? Bool) ?? false
            }.count

            let changeCount = weeklyCount - previousWeekCount
            print("명상 변화량: \(changeCount)")

            if weeklyCount > 0 {
                self.hasRealData = true
                print("실제 명상 데이터 발견")
            }

            return MeditationData(
                weeklyCount: weeklyCount,
                changeCount: changeCount
            )

        } catch {
            print("명상 데이터 로드 오류: \(error)")
            return MeditationData(weeklyCount: 0, changeCount: 0)
        }
    }

    private func generateAIInsight(
        planCompletion: PlanCompletionData,
        exercise: ExerciseData,
        sleep: SleepData,
        meditation: MeditationData,
        hasRealData: Bool
    ) -> AIInsightData {

        print("AI 인사이트 생성 중...")
        print("- 일정: \(planCompletion.completedItems)/\(planCompletion.totalItems)")
        print("- 걸음수: \(exercise.averageSteps)")
        print("- 수면: \(sleep.averageHours)시간")
        print("- hasRealData: \(hasRealData)")

        if planCompletion.totalItems == 0 {
            print("일정이 없음 - 일정 추가 권유")
            return AIInsightData(message: "오늘 일정을 추가해보세요. 체계적인 관리가 건강의 시작이에요!")
        }

        if !hasRealData {
            print("실제 데이터 없음 - 대기 메시지")
            return AIInsightData(message: "활동을 시작하면 맞춤 분석을 제공해드릴게요!")
        }

        var insights: [String] = []

        let completionRate = planCompletion.completionRate
        if completionRate >= 0.8 {
            insights.append("오늘 계획을 \(Int(completionRate * 100))% 달성했어요! 훌륭해요")
        } else if completionRate >= 0.5 {
            insights.append("오늘 계획을 절반 이상 완료했어요. 조금만 더 힘내세요!")
        } else if planCompletion.totalItems > 0 {
            let remaining = planCompletion.totalItems - planCompletion.completedItems
            if remaining == 1 {
                insights.append("오늘 1개 일정이 남았어요. 마지막 스퍼트!")
            } else {
                insights.append("오늘 \(remaining)개 일정이 남았어요. 하나씩 차근차근 해보세요!")
            }
        }

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

        if meditation.weeklyCount >= 5 {
            insights.append("이번 주 \(meditation.weeklyCount)회 명상으로 마음이 평온해졌을 거예요")
        } else if meditation.weeklyCount >= 3 {
            insights.append("꾸준한 명상이 좋은 습관이 되고 있네요")
        } else if meditation.weeklyCount > 0 {
            insights.append("명상을 시작했네요! 꾸준히 이어가 보세요")
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

    private func getUserName() -> String {
        let coreDataService = CoreDataService.shared

        do {
            let userRequest = NSFetchRequest<NSManagedObject>(entityName: "UserEntity")
            userRequest.fetchLimit = 1

            let users = try coreDataService.context.fetch(userRequest)

            if let user = users.first,
               let nickname = user.value(forKey: "nickname") as? String,
               !nickname.isEmpty {
                print("사용자 이름 발견: \(nickname)")
                return nickname
            }
        } catch {
            print("CoreData에서 사용자 닉네임 가져오기 실패: \(error)")
        }

        print("기본 사용자 이름 사용")
        return "사용자"
    }

    func refreshData() async {
        print("수동 새로고침 시작")
        await loadHealthData()
    }
}

@objc(ScheduledActivity)
public class ScheduledActivity: NSManagedObject {
    @NSManaged public var date: Date?
    @NSManaged public var title: String?
    @NSManaged public var category: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var completedAt: Date?
}
