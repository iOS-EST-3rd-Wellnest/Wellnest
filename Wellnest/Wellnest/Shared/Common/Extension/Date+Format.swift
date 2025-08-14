//
//  File.swift
//  Wellnest
//
//  Created by 박동언 on 8/6/25.
//


import SwiftUI

extension Date {
    var formattedTime: String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: self)
    }

    func dateFormat(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko-KR")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    static var weekdays: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.shortStandaloneWeekdaySymbols
    }
}
