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
    
    @State private var isAuthorizing: Bool = false
    @State private var showSettingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let manager = HealthManager()
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 40) {
                HStack {
                    Image(systemName: "shoeprints.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading) {
                        Text("당신의 건강여정을 시작하세요")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Apple 건강앱과 연동하여 걸음수, 수면, 심박수 등 건강데이터를 자동으로 기록합니다.")
                            .font(.footnote)
                    }
                }
                
                HStack {
                    Image(systemName: "iphone")
                        .foregroundStyle(.blue)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading) {
                        Text("하루의 건강 리포트를 한눈에")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Apple 건강앱과 연동시 오늘의 활동량, 칼로리, 수면시간을 한 화면에서 확인할 수 있습니다.")
                            .font(.footnote)
                    }
                }
                
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundStyle(.blue)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading) {
                        Text("목표 달성의 시작")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("건강 데이터를 기반으로 매일의 성취를 확인하세요.")
                            .font(.footnote)
                    }
                }
            }
            
            if userDefault.isHealthKitEnabled {
                VStack {
                    Text("연동 완료")
                    
                    Text("걸음수: \(stepCount)")
                    Text("칼로리: \(caloriesCount)")
                    Text("수면 시간: \(formattedSleepTime)")
                    Text("심박수: \(heartRate)")
                    Text("BMI: \(String(format: "%.1f", bmi))")
                    Text("체지방률: \(String(format: "%.1f", bodyFatPercentage))%")
                }
            }
            
            Spacer()
            
            FilledButton(title: userDefault.isHealthKitEnabled ? "건강 앱 연동 됨" : "건강 앱 연동하기", action: {
                Task {
                    await connectHealthKit()
                }
            }, backgroundColor: userDefault.isHealthKitEnabled ? .gray : .blue)
            .disabled(userDefault.isHealthKitEnabled)
            
            Text("* 설정 > 건강 > 데이터 접근 및 기기 > Wellnest에서 연동목록을 변경할 수 있습니다.")
                .font(.caption)
            
        }
        .padding()
        .navigationTitle("건강 앱 연동")
        .navigationBarTitleDisplayMode(.inline)
        .padding(.bottom, 100)
        .onAppear {
            if userDefault.isHealthKitEnabled {
                Task {
                    try await fetchHealthData()
                }
                startObserversIfNeeded()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .healthDataDidUpdate)) { _ in
            Task {
                try await fetchHealthData()
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active, userDefault.isHealthKitEnabled {
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    
                    await refreshHealthData()
                }
            }
        }
        .alert("건강 앱 연동 오류", isPresented: $showSettingAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("닫기", role: .cancel) { }
        } message: { Text(alertMessage) }
    }
}

extension HealthKitInterworkView {
    @MainActor
    private func connectHealthKit() async {
        if userDefault.isHealthKitEnabled {
            await refreshHealthData()
            return
        } else {
            userDefault.isHealthKitEnabled = false
        }
        
        isAuthorizing = true
        defer { isAuthorizing = false }
        
        do {
            try await manager.requestAuthorization()
            try? await Task.sleep(for: .milliseconds(200))
            
            userDefault.isHealthKitEnabled = true
            try await fetchHealthData()
            startObserversIfNeeded()
            print("건강 앱 연동")
        } catch {
            userDefault.isHealthKitEnabled = false
            alertMessage = "건강 데이터 접근에 실패했습니다.\n설정에서 권한을 확인해주세요."
            showSettingAlert = true
        }
    }
    
    /// 건강앱의 데이터가 변경 시  업데이트
    private func startObserversIfNeeded() {
        if let step = HKObjectType.quantityType(forIdentifier: .stepCount) {
            manager.startObservingUpdates(for: step)
        }
        if let calories = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            manager.startObservingUpdates(for: calories)
        }
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            manager.startObservingUpdates(for: heartRate)
        }
        if let sleepTime = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            manager.startObservingUpdates(for: sleepTime)
        }
    }
    
    /// 데이터 패치
    func fetchHealthData() async throws {
        stepCount = try await manager.fetchStepCount()
        caloriesCount = try await manager.fetchCalorieCount()
        sleepTime = Int(try await manager.fetchSleepDuration())
        heartRate = try await manager.fetchAverageHeartRate()
        bmi = try await manager.fetchBMI()
        bodyFatPercentage = try await manager.fetchBodyFatPercentage()
    }
    
    @MainActor
    /// 기존 앱 연동 비활성화 -> 활성화 시 데이터 패치
    func refreshHealthData() async {
        do {
            try await fetchHealthData()
        } catch {
            alertMessage = "데이터 갱신 중 오류가 발생했습니다."
            showSettingAlert = true
        }
    }
}

#Preview {
    HealthKitInterworkView()
}
