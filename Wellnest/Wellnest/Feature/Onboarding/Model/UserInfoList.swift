//
//  UserInfoList.swift
//  Wellnest
//
//  Created by 정소이 on 8/14/25.
//

import Foundation

struct UserInfo: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct UserInfoOptions {
    static let ageRanges = [
        UserInfo(title: "10대", value: "10대"),
        UserInfo(title: "20대", value: "20대"),
        UserInfo(title: "30대", value: "30대"),
        UserInfo(title: "40대", value: "40대"),
        UserInfo(title: "50대", value: "50대"),
        UserInfo(title: "60대 이상", value: "60대 이상")
    ]

    static let genders = [
        UserInfo(title: "여성 👩🏻", value: "여성"),
        UserInfo(title: "남성 👨🏻", value: "남성")
    ]
}
