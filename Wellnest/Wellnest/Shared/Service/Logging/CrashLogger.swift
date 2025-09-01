//
//  CrashLogger.swift
//  Wellnest
//
//  Created by Heejung Yang on 9/1/25.
//

import FirebaseCrashlytics

protocol CrashLogger {
    func log(_ msg: String)
    func set(_ value: Any?, forKey key: String)
    func record(_ error: Error, userInfo: [String: Any]?)
}

struct CrashlyticsLogger: CrashLogger {
    func log(_ msg: String) {
        Crashlytics.crashlytics().log(msg)
    }
    func set(_ value: Any?, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value ?? "nil", forKey: key)
    }
    func record(_ error: Error, userInfo: [String: Any]?) {
        let cr = Crashlytics.crashlytics()
        userInfo?.forEach { cr.setCustomValue($0.value, forKey: "ctx.\($0.key)") }
        cr.record(error: error) // Non-Fatal
    }
}
