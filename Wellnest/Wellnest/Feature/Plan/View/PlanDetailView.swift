//
//  PlanDetailView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/22/25.
//

import SwiftUI

struct PlanDetailView: View {
    let schedule: ScheduleItem
    var body: some View {
        VStack {
            Text(schedule.title)
        }
        .background(Color("schedule.backgroundColor"))
    }
}

