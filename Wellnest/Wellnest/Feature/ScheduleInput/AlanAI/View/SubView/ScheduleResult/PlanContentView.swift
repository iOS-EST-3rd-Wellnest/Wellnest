//
//  PlanContentView.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct PlanContentView: View {
    let plan: HealthPlanResponse
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                PlanHeaderSectionResult(plan: plan)
                
                SchedulesSection(schedules: plan.schedules)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}
