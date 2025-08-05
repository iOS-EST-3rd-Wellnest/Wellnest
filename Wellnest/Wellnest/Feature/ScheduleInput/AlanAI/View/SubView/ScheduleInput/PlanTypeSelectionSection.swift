//
//  PlanTypeSelectionSection.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct PlanTypeSelectionSection: View {
    @Binding var selectedPlanType: PlanType
    let onPlanTypeChanged: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("플랜 유형을 선택해주세요")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(PlanType.allCases, id: \.self) { planType in
                    PlanTypeCard(
                        planType: planType,
                        isSelected: selectedPlanType == planType
                    ) {
                        selectedPlanType = planType
                        onPlanTypeChanged()
                    }
                }
            }
        }
    }
}

#Preview {
    PlanTypeSelectionSection(
        selectedPlanType: .constant(.single),
        onPlanTypeChanged: { }
    )
    .padding()
}
