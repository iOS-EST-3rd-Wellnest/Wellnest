//
//  HealthKitInterworkView.swift
//  Wellnest
//
//  Created by 전광호 on 8/1/25.
//

import SwiftUI
import HealthKit

struct HealthKitInterworkView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject private var userDefault = UserDefaultsManager.shared
    
    @State private var stepCount: Int = 0
    @State private var caloriesCount: Int = 0
    @State private var sleepTime: Int = 0
    @State private var heartRate: Int = 0
    @State private var bmi: Double = 0.0
    @State private var bodyFatPercentage: Double = 0.0
    
    var formattedSleepTime: String {
        let minutes = sleepTime / 60
        let hour = minutes / 60
        let minute = minutes % 60
        return "\(hour)시간 \(minute)분"
    }
    
    @State private var showSettingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let manager = HealthManager()
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("건강앱과 연동하여 건강정보를 가져옵니다.")
                .padding()
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lineWidth: 1)
                }
            
            Toggle(isOn: $userDefault.isHealthKitEnabled) {
                Text("건강앱 연동하기")
            }
            .onChange(of: userDefault.isHealthKitEnabled) { newValue in
                if newValue {
                    Task {
                        do {
                            try await manager.requestAuthorization()
                            try await fetchHealthData()
                            
                        } catch {
                            userDefault.isHealthKitEnabled = false
                            alertMessage = "건강 데이터 접근에 실패했습니다.\n설정에서 권한을 확인해주세요."
                            showSettingAlert = true
                        }
                    }
                } else {
                    stepCount = 0
                    caloriesCount = 0
                    sleepTime = 0
                    heartRate = 0
                    bmi = 0.0
                    bodyFatPercentage = 0.0
                }
            }
            
            .alert("건강 앱 연동 실패", isPresented: $showSettingAlert) {
                Button("설정으로 이동") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("취소", role: .cancel) {
                    userDefault.isHealthKitEnabled = false
                }
            } message: {
                Text(alertMessage)
            }
            
            if userDefault.isHealthKitEnabled {
                VStack(spacing: 8) {
                    Text("걸음수: \(stepCount)걸음")
                    Text("소모 칼로리: \(caloriesCount) kcal")
                    Text("수면 시간: \(formattedSleepTime)")
                    Text("심박수: \(heartRate) bpm")
                    Text("BMI: \(String(format: "%.1f", bmi))")
                    Text("체지방률: \(String(format: "%.1f", bodyFatPercentage))%")
                }
                .padding(.top)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("헬스킷 연동")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if userDefault.isHealthKitEnabled {
                Task {
                    try await fetchHealthData()
                }
                
                if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
                    manager.startObservingUpdates(for: stepType)
                }
                if let calorieType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
                    manager.startObservingUpdates(for: calorieType)
                }
                if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
                    manager.startObservingUpdates(for: heartRateType)
                }
                if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                    manager.startObservingUpdates(for: sleepType)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .healthDataDidUpdate)) { _ in
            Task {
                try await fetchHealthData()
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active && userDefault.isHealthKitEnabled {
                Task {
                    await refreshHealthData()
                }
            }
        }
    }
    
    func fetchHealthData() async throws {
        stepCount = try await manager.fetchStepCount()
        caloriesCount = try await manager.fetchCalorieCount()
        sleepTime = Int(try await manager.fetchSleepDuration())
        heartRate = try await manager.fetchAverageHeartRate()
        bmi = try await manager.fetchBMI()
        bodyFatPercentage = try await manager.fetchBodyFatPercentage()
    }
    
    /// 앱으로 복귀 후 권한이 허용된 경우 최신 데이터 다시 가져오기
    func refreshHealthData() async {
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let status = HKHealthStore().authorizationStatus(for: stepType)
            if status == .sharingAuthorized {
                do {
                    stepCount = try await manager.fetchStepCount()
                    caloriesCount = try await manager.fetchCalorieCount()
                    sleepTime = Int(try await manager.fetchSleepDuration())
                    heartRate = try await manager.fetchAverageHeartRate()
                    bmi = try await manager.fetchBMI()
                    bodyFatPercentage = try await manager.fetchBodyFatPercentage()
                    
                } catch {
                    alertMessage = "데이터 갱신 중 오류가 발생했습니다."
                    showSettingAlert = true
                }
            }// else {
            //                userDefault.isHealthKitEnabled = false
            //                alertMessage = "건강 앱 권한이 해제되었습니다.\n설정에서 다시 허용해주세요."
            //                showSettingAlert = true
            //            }
        }
    }
}

#Preview {
    HealthKitInterworkView()
}
