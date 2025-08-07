//
//  UserAgeRange.swift
//  Wellnest
//
//  Created by 전광호 on 8/1/25.
//

import Foundation

enum UserAgeRange: String, CaseIterable, Identifiable {
    case teens = "10대"
    case twenties = "20대"
    case thirties = "30대"
    case forties = "40대"
    case fifties = "50대"
    case moreThenSixty = "60대 이상"
    
    var id: String {
        self.rawValue
    }
}
