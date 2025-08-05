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
    
    @State private var isOn: Bool = false // 추후 UserDefault로 저장 가능
    
    @State private var stepCount: Int = 0
    @State private var caloriesCount: Int = 0
    @State private var sleepTime: Int = 0
    
    var formattedSleepTime: String {
        let hour = sleepTime / 60
        let minute = sleepTime % 60
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
            
            Toggle(isOn: $isOn) {
                Text("건강앱 연동하기")
            }
            .onChange(of: isOn) { newValue in
                if newValue {
                    // 권한 상태 확인 (대표적으로 stepCount로 검사)
                    if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
                        let status = HKHealthStore().authorizationStatus(for: stepType)
                        
                        if status == .sharingDenied {
                            isOn = false
                            alertMessage = "건강 앱 접근 권한이 거부되어 있습니다.\n설정에서 접근을 허용해주세요."
                            showSettingAlert = true
                            return
                        }
                    }
                    
                    Task {
                        do {
                            try await manager.requestAuthorization()
                            stepCount = try await manager.fetchStepCount()
                            caloriesCount = try await manager.fetchCalorieCount()
                            sleepTime = Int(try await manager.fetchSleepDuration())
                        } catch {
                            isOn = false
                            alertMessage = "건강 데이터 접근에 실패했습니다.\n설정에서 권한을 확인해주세요."
                            showSettingAlert = true
                        }
                    }
                } else {
                    stepCount = 0
                    caloriesCount = 0
                    sleepTime = 0
                }
            }
            .alert("건강 앱 연동 실패", isPresented: $showSettingAlert) {
                Button("설정으로 이동") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("취소", role: .cancel) {
                    isOn = false
                }
            } message: {
                Text(alertMessage)
            }
            
            if isOn {
                VStack(spacing: 8) {
                    Text("걸음수: \(stepCount)걸음")
                    Text("소모 칼로리: \(caloriesCount) kcal")
                    Text("수면 시간: \(formattedSleepTime)")
                }
                .padding(.top)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("헬스킷 연동")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { phase in
            if phase == .active && isOn {
                Task {
                    await refreshHealthData()
                }
            }
        }
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
                    isOn = true
                } catch {
                    alertMessage = "데이터 갱신 중 오류가 발생했습니다."
                    showSettingAlert = true
                }
            } else {
                isOn = false
                alertMessage = "건강 앱 권한이 해제되었습니다.\n설정에서 다시 허용해주세요."
                showSettingAlert = true
            }
        }
    }
}

#Preview {
    HealthKitInterworkView()
}
