//
//  PlanTypeSelectionSection.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct PlanTypeSelectionSection: View {
    @Binding var selectedPlanType: PlanType
    let onPlanTypeChanged: (PlanType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.layout) {
            Text("플랜 유형을 선택해주세요")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.layout) {
                ForEach(PlanType.allCases, id: \.self) { planType in
                    PlanTypeCard(
                        planType: planType,
                        isSelected: selectedPlanType == planType
                    ) {
                        onPlanTypeChanged(planType)
                    }
                }
            }
        }
    }
}

#Preview {
    PlanTypeSelectionSection(
        selectedPlanType: .constant(.single),
        onPlanTypeChanged: { _ in }
    )
    .padding()
}
