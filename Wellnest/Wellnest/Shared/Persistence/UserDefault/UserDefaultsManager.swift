//
//  UserDefaultsManager.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import Foundation

final class UserDefaultsManager: ObservableObject {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard

    @Published var isOnboarding: Bool {
        didSet {
            defaults.set(isOnboarding, forKey: UserDefaultsKeys.Onboarding.isOnboarding)
        }
    }

    private init() {
        self.isOnboarding = defaults.bool(forKey: UserDefaultsKeys.Onboarding.isOnboarding)
    }

    // Codable 저장
    func save<T: Codable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            defaults.set(encoded, forKey: key)
        }
    }

    // Codable 불러오기
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        if let data = defaults.data(forKey: key) {
            let decoder = JSONDecoder()
            return try? decoder.decode(type, from: data)
        }
        return nil
    }

    // Codable 삭제
    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
