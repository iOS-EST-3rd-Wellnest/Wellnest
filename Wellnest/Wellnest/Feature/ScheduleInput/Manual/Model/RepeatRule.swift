//
//  RepeatRule.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import Foundation

struct RepeatRule: TagModel {
    let id = UUID()
    let name: String

    static let tags: [RepeatRule] = [
        RepeatRule(name: "매일"),
        RepeatRule(name: "매주"),
        RepeatRule(name: "매월"),
        RepeatRule(name: "매년")
    ]

    init(name: String) {
        self.name = name
    }
}
