//
//  UserDefaultsManager.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import Foundation

/// 앱 전역에서 UserDefaults 값을 관리하기 위한 싱글톤 클래스
final class UserDefaultsManager: ObservableObject {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard

    /// 온보딩 완료 여부
    @Published var isOnboarding: Bool {
        didSet {
            defaults.set(isOnboarding, forKey: UserDefaultsKeys.Onboarding.isOnboarding)
        }
    }
    
    /// 건강 앱 동기화 여부
    @Published var isHealthKitEnabled: Bool {
        didSet {
            defaults.set(isHealthKitEnabled, forKey: UserDefaultsKeys.Settings.isHealthDataEnabled)
        }
    }
    
    /// 알림 설정 토글 여부
    @Published var isNotificationEnabled: Bool {
        didSet {
            defaults.set(isNotificationEnabled, forKey: UserDefaultsKeys.Settings.isNotificationEnabled)
        }
    }
    
    /// 캘린더 연동 여부
    @Published var isCalendarEnabled: Bool {
        didSet {
            defaults.set(isCalendarEnabled, forKey: UserDefaultsKeys.Settings.isCalendarEnable)
        }
    }

    private init() {
        self.isOnboarding = defaults.bool(forKey: UserDefaultsKeys.Onboarding.isOnboarding)
        self.isHealthKitEnabled = defaults.bool(forKey: UserDefaultsKeys.Settings.isHealthDataEnabled)
        self.isNotificationEnabled = defaults.bool(forKey: UserDefaultsKeys.Settings.isNotificationEnabled)
        self.isCalendarEnabled = defaults.bool(forKey: UserDefaultsKeys.Settings.isCalendarEnable)
    }

    /// Codable 객체를 JSON으로 인코딩해 UserDefaults에 저장
    /// - Parameters:
    ///   - object: 저장할 Codable 객체
    ///   - key: 저장할 키 (UserDefaultsKeys에서 관리)
    /// ex) UserDefaultsManager.shared.save(user, forKey: 키 값)
    func save<T: Codable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            defaults.set(encoded, forKey: key)
        }
    }

    /// UserDefaults에 저장된 JSON 데이터를 Codable 타입으로 디코딩해 반환
    /// - Parameters:
    ///   - type: 반환할 타입 (`User.self` 등)
    ///   - key: 가져올 키
    /// - Returns: 디코딩된 객체 또는 nil
    /// ex) let user = UserDefaultsManager.shared.load(User.self, forKey: 키 값)
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        if let data = defaults.data(forKey: key) {
            let decoder = JSONDecoder()
            return try? decoder.decode(type, from: data)
        }
        return nil
    }

    /// 지정된 키에 해당하는 값을 UserDefaults에서 제거
    /// - Parameter key: 삭제할 키
    // ex) UserDefaultsManager.shared.remove(forKey: "UserDefaultsKeys에 있는 키 값")
    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
