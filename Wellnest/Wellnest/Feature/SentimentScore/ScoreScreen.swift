//
//  ScoreScreen.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/21/25.
//

import SwiftUI

// 화면에서 뷰모델 구성
struct ScoreScreen: View {
    @StateObject private var loc = LocationManager()

    // OpenWeatherAdapter에 좌표 제공

    @StateObject private var userDefault = UserDefaultsManager.shared
    private let healthManager = HealthManager()
    @ObservedObject var vm: SentimentalScoreViewModel


    var body: some View {
        VStack(spacing: 16) {
            if vm.isLoading {
                ProgressView("계산 중…")
            } else {
                SentimentalGaugeView(
                    score: vm.scoreEMA,
                    subtitle: "오늘 컨디션",
                    breakdown: vm.breakdown,
                    feedback: SentimentalFeedbackBuilder.make(
                        .init(score: vm.scoreEMA,
                              weatherSub: vm.breakdown.weather,
                              moodSub: vm.breakdown.mood,
                              healthSub: vm.breakdown.health,
                              preferredWeather: vm.preferredWeather,
                              currentCondition: vm.currentWeather?.condition)
                    )
                )
            }

            Button("점수 갱신") {
                // 최신 좌표를 쓰도록 어댑터 교체 후 로드
                Task {
                    // 주입한 서비스만 교체하고 싶다면,
                    // 뷰모델을 새로 만들거나, 뷰모델에 setter를 추가해도 됩니다.
                    await vm.loadAndCompute(persist: true)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .task {
            // 앱 진입 시 1회 계산 (초기 디폴트 좌표로)
            var hInputs: HealthInputs?
            if userDefault.isHealthKitEnabled {
                // 각각의 fetch가 async throws 라고 가정
                let sleepHours: Double? = try? await healthManager.fetchSleepDuration()
                // fetchStepCount()가 Double을 리턴하면 Int로 변환
                let steps: Double? = (try? await healthManager.fetchStepCount()).map(Double.init)
                let averageHR: Double? = (try? await healthManager.fetchAverageHeartRate()).map(Double.init) // 평균 심박을 'restingHR'에 매핑
                let activeCalories: Double? = (try? await healthManager.fetchCalorieCount()).map(Double.init)

                hInputs = HealthInputs(
                    sleepHours: sleepHours,
                    steps: steps,
                    averageHR: averageHR,          // ✅ 라벨명 맞추기 (averageHR 아님)
                    activeCalories: activeCalories
                )
                vm.hInputs = hInputs
                print(hInputs)
            }
            await vm.loadAndCompute(persist: true)
        }
    }
}

