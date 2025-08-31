//
//  HealthKitInterworkView.swift
//  Wellnest
//
//  Created by 전광호 on 8/1/25.
//

import SwiftUI
import HealthKit

struct HealthKitInterworkView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hsClass
    
    @EnvironmentObject private var hiddenTabBar: TabBarState
    
    @StateObject private var userDefault = UserDefaultsManager.shared
    
    @State private var stepCount: Int = 0
    @State private var caloriesCount: Int = 0
    @State private var sleepTime: Int = 0
    @State private var heartRate: Int = 0
    @State private var bmi: Double = 0.0
    @State private var bodyFatPercentage: Double = 0.0
    
    @State private var isAuthorizing: Bool = false
    @State private var showSettingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let manager = HealthManager()
    
    var body: some View {
        VStack(alignment: .center) {
            
            Spacer()
            
            VStack(alignment: .leading, spacing: vstackSpacing) {
                HStack {
                    Image(systemName: "shoeprints.fill")
                        .foregroundStyle(.wellnestOrange)
                        .font(.system(size: stepSymbolSize))
                    
                    VStack(alignment: .leading) {
                        Text("당신의 건강여정을 시작하세요")
                            .font(titleFont)
                            .fontWeight(.bold)
                        
                        Text("Apple 건강앱과 연동하여 걸음수, 수면 등 건강데이터를 자동으로 기록합니다.")
                            .foregroundStyle(.secondary)
                            .font(subTitleFont)
                    }
                }
                
                HStack {
                    Image(systemName: "iphone")
                        .foregroundStyle(.wellnestOrange)
                        .font(.system(size: iphoneSymbolSize))
                    
                    VStack(alignment: .leading) {
                        Text("하루의 건강 리포트를 한눈에")
                            .font(titleFont)
                            .fontWeight(.bold)
                        
                        Text(title)
                            .foregroundStyle(.secondary)
                            .font(subTitleFont)
                    }
                }
                
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundStyle(.wellnestOrange)
                        .font(.system(size: chartSymbolSize))
                    
                    VStack(alignment: .leading) {
                        Text("목표 달성의 시작")
                            .font(titleFont)
                            .fontWeight(.bold)
                        
                        Text("건강 데이터를 기반으로 매일의 성취를 확인하세요.")
                            .foregroundStyle(.secondary)
                            .font(subTitleFont)
                    }
                }
            }
            .padding()
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(Color.wellnestOrange.opacity(0.4), lineWidth: 1)
            }
            
            Spacer()
            
            Text("건강 > 데이터 접근 및 기기 > Wellnest에서 연동목록을 변경할 수 있습니다.")
                .padding(.bottom, Spacing.inline)
                .foregroundStyle(.secondary)
                .font(.caption2)
            
            FilledButton(
                title: isAuthorizing ? "연동 중..." : (userDefault.isHealthKitEnabled ? "건강 앱 연동 됨" : "건강 앱 연동하기"),
                disabled: userDefault.isHealthKitEnabled
            ) {
                Task {
                    await connectHealthKit()
                }
            }
            .layoutWidth()
            .tabBarGlassBackground()
        }
        .padding(.horizontal)
        .padding(.bottom, Spacing.content)
        .navigationTitle("건강 앱 연동")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                let snap = await manager.finalAuthSnapshot()
                if !snap.missingCore.isEmpty {
                    userDefault.isHealthKitEnabled = false
                }
                // 연결됨(=true)인 경우에만 패치/옵저버
                if userDefault.isHealthKitEnabled {
                    await fetchHealthDataSafely()
                    startObserversIfNeeded()
                }
            }
            hiddenTabBar.isHidden = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .healthDataDidUpdate)) { _ in
            Task { await fetchHealthDataSafely() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task {
                    await resyncAuthorizationFlag()
                    
                    if userDefault.isHealthKitEnabled {
                        startObserversIfNeeded()
                        await refreshHealthData()
                    }
                }
            }
        }
        .alert("건강 앱 연동 오류", isPresented: $showSettingAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) { }
        } message: { Text(alertMessage) }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    hiddenTabBar.isHidden = false
                    withAnimation { dismiss() }
                } label: {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.wellnestOrange)
                }
            }
        }
    }
}

extension HealthKitInterworkView {
    @MainActor
    private func connectHealthKit() async {
        print("isEnabled:", userDefault.isHealthKitEnabled)
        
        // 요청 전 스냅샷
        let pre = await manager.finalAuthSnapshot()
        print("1")
        print("pre.missingCore:", pre.missingCore.map(krName).joined(separator: ", "))
        print("pre.missingOptional:", pre.missingOptional.map(krName).joined(separator: ", "))
        
        if pre.missingCore.isEmpty {
            // 권한 허용
            print("2")
            userDefault.isHealthKitEnabled = true
            await fetchHealthDataSafely()
            startObserversIfNeeded()
            return
        }
        
        // 권한이 필요한 경우에 요청
        do {
            print("3")
            let _ = try await manager.requestAuthorizationIfNeeded()
            try await Task.sleep(for: .milliseconds(150))
            let post = await manager.finalAuthSnapshot()
            print("post.missingCore:", post.missingCore.map(krName).joined(separator: ", "))
            print("post.missingOptional:", post.missingOptional.map(krName).joined(separator: ", "))
            if post.missingCore.isEmpty {
                print("연동성공")
                
                // 연동 성공
                userDefault.isHealthKitEnabled = true
                await fetchHealthDataSafely()
                startObserversIfNeeded()
                print("권한 상태: \(userDefault.isHealthKitEnabled)")
                
                // 선택 부족은 비차단
                if !post.missingOptional.isEmpty {
                    print("Optional not granted:", post.missingOptional.map(krName).joined(separator: ", "))
                }
                print("isEnabled:", userDefault.isHealthKitEnabled)
            } else {
                print("4")
                // 설정 이동
                userDefault.isHealthKitEnabled = false
                alertMessage =
                    """
                    건강 데이터 접근이 부족합니다.
                    부족한 항목: \(post.missingCore.map(krName).joined(separator: ", "))
                    설정 > 건강 > 데이터 접근 및 기기에서 허용해 주세요.
                    """
                showSettingAlert = true
            }
        } catch HealthAuthError.notAvailable {
            userDefault.isHealthKitEnabled = false
            alertMessage = "이 기기에서는 건강 데이터가 지원되지 않습니다."
            showSettingAlert = false
        } catch HealthAuthError.unknown(let e) {
            userDefault.isHealthKitEnabled = false
            alertMessage = "연동 중 오류가 발생했습니다. (\(e.localizedDescription))"
            showSettingAlert = false
        } catch {
            userDefault.isHealthKitEnabled = false
            alertMessage = "연동 중 알 수 없는 오류가 발생했습니다."
            showSettingAlert = false
        }
    }
    
    private func krName(for type: HKObjectType) -> String {
        switch type {
        case HKObjectType.quantityType(forIdentifier: .stepCount): return "걸음 수"
        case HKObjectType.quantityType(forIdentifier: .activeEnergyBurned): return "활동 에너지(칼로리)"
        case HKObjectType.quantityType(forIdentifier: .heartRate): return "심박수"
        case HKObjectType.categoryType(forIdentifier: .sleepAnalysis): return "수면"
        case HKObjectType.quantityType(forIdentifier: .bodyMassIndex): return "BMI"
        case HKObjectType.quantityType(forIdentifier: .bodyFatPercentage): return "체지방률"
        default: return "기타 항목"
        }
    }
    
//    /// 건강앱의 데이터가 변경 시  업데이트
    private func startObserversIfNeeded() {
        guard userDefault.isHealthKitEnabled else { return }
        
        if let step = HKObjectType.quantityType(forIdentifier: .stepCount) {
            manager.startObservingUpdates(for: step)
        }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            manager.startObservingUpdates(for: energy)
        }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) {
            manager.startObservingUpdates(for: hr)
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            manager.startObservingUpdates(for: sleep)
        }
    }
    
    func fetchHealthDataSafely() async {
        async let steps: Int = (try? manager.fetchStepCount()) ?? 0
        async let calories: Int = (try? manager.fetchCalorieCount()) ?? 0
        async let sleep: Double = (try? manager.fetchSleepDuration()) ?? 0
        async let hr: Int = (try? manager.fetchAverageHeartRate()) ?? 0
        async let bmiVal: Double = (try? manager.fetchBMI()) ?? 0
        async let fatVal: Double = (try? manager.fetchBodyFatPercentage()) ?? 0
        
        let (s, c, sl, h, b, f) = await (steps, calories, sleep, hr, bmiVal, fatVal)
        stepCount = s
        caloriesCount = c
        sleepTime = Int(sl)
        heartRate = h
        bmi = b
        bodyFatPercentage = f
    }
    
    @MainActor
    /// 기존 앱 연동 비활성화 -> 활성화 시 데이터 패치
    func refreshHealthData() async {
        do {
            await fetchHealthDataSafely()
            startObserversIfNeeded()
        }
    }
    
    private func resyncAuthorizationFlag() async {
        let snap = await manager.authorizationSnapshotByReadProbe()
        
        if !snap.missingCore.isEmpty {
            userDefault.isHealthKitEnabled = false
        }
    }
}

extension HealthKitInterworkView {
    var vstackSpacing: CGFloat {
        if hsClass == .compact {
            return 40
        } else {
            return 60
        }
    }
    
    var stepSymbolSize: CGFloat {
        if hsClass == .compact {
            return 32
        } else {
            return 52
        }
    }
    
    var iphoneSymbolSize: CGFloat {
        if hsClass == .compact {
            return 40
        } else {
            return 60
        }
    }
    
    var chartSymbolSize: CGFloat {
        if hsClass == .compact {
            return 30
        } else {
            return 50
        }
    }
    
    var titleFont: Font {
        if hsClass == .compact {
            return .title3
        } else {
            return .title
        }
    }
    
    var subTitleFont: Font {
        if hsClass == .compact {
            return .footnote
        } else {
            return .body
        }
    }
    
    var title: String {
        if hsClass == .compact {
            return "Apple 건강앱과 연동시 오늘의 활동량, 칼로리, 수면시간을 한 화면에서 확인할 수 있습니다."
        } else {
            return "Apple 건강앱과 연동시 오늘의 활동량, 칼로리, 수면시간을 한 화면에서 \n확인할 수 있습니다."
        }
    }
}

#Preview {
    HealthKitInterworkView()
        .environmentObject(TabBarState())
}
