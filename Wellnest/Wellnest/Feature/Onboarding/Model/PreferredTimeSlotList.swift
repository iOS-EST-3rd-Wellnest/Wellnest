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
    let title: String
    var isSelected: Bool = false

    static let timeSlots: [PreferredTimeSlot] = [
        PreferredTimeSlot(icon: "🌞", title: "오전"),
        PreferredTimeSlot(icon: "🕛", title: "점심"),
        PreferredTimeSlot(icon: "🕖", title: "오후"),
        PreferredTimeSlot(icon: "🌜", title: "밤/새벽"),
        PreferredTimeSlot(icon: "❔", title: "기타"),
        PreferredTimeSlot(icon: "💬", title: "특별히 없음")
    ]
}
