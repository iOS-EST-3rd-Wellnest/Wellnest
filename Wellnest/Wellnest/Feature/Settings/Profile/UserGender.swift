//
//  UserGender.swift
//  Wellnest
//
//  Created by 전광호 on 8/1/25.
//

import Foundation

enum UserGender: String, CaseIterable, Identifiable {
    case male = "남성"
    case female = "여성"
    
    var id: String {
        self.rawValue
    }
}
