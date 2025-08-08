//
//  PlanHeaderSectionResult.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct PlanHeaderSectionResult: View {
    let plan: HealthPlanResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: planTypeIcon(plan.planType))
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(planTypeDisplayName(plan.planType))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }

                Spacer()
            }

            if let description = plan.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func planTypeIcon(_ planType: String) -> String {
        switch planType {
        case "single": return "calendar.badge.plus"
        case "multiple": return "calendar"
        case "routine": return "repeat"
        default: return "calendar"
        }
    }

    private func planTypeDisplayName(_ planType: String) -> String {
        switch planType {
        case "single": return "단일 일정"
        case "multiple": return "여러 일정"
        case "routine": return "루틴"
        default: return "일정"
        }
    }
}

#Preview {
    PlanHeaderSectionResult(
        plan: HealthPlanResponse(
            planType: "routine",
            title: "주 3회 헬스 루틴",
            description: "근력 증진을 위한 체계적인 운동 계획입니다.",
            schedules: []
        )
    )
    .padding()
}
