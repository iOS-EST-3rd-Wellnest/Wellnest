//
//  PlanTypeCard.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct PlanTypeCard: View {
    let planType: PlanType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: planType.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)

                Text(planType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    HStack {
        PlanTypeCard(planType: .single, isSelected: false) { }
        PlanTypeCard(planType: .multiple, isSelected: true) { }
        PlanTypeCard(planType: .routine, isSelected: false) { }
    }
    .padding()
}
