//
//  PlanHeaderSectionResult.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct PlanHeaderSectionResult: View {
    @Environment(\.colorScheme) private var colorScheme
    let plan: HealthPlanResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: planTypeIcon(plan.planType))
                    .foregroundColor(.wellnestOrange)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(planTypeDisplayName(plan.planType))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.wellnestOrange.opacity(0.1))
                        .foregroundColor(.wellnestOrange)
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
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
        .roundedBorder(cornerRadius: 12)
        .defaultShadow()
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
