//
//  PreferredTimeSlotList.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import Foundation

struct PreferredTimeSlot: SelectableItem {
    let id = UUID()
    let icon: String
    let category: String
    var isSelected: Bool = false

    static let timeSlots: [PreferredTimeSlot] = [
        PreferredTimeSlot(icon: "🌞", category: "오전"),
        PreferredTimeSlot(icon: "🕛", category: "점심"),
        PreferredTimeSlot(icon: "🕖", category: "오후"),
        PreferredTimeSlot(icon: "🌜", category: "밤/새벽"),
        PreferredTimeSlot(icon: "❔", category: "기타"),
        PreferredTimeSlot(icon: "💬", category: "특별히 없음")
    ]
}
