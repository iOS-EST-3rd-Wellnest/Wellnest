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
            VStack(spacing: Spacing.content) {
                Image(systemName: planType.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .wellnestOrange : .primary)

                Text(planType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .wellnestOrange : .primary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.wellnestOrange.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(isSelected ? Color.wellnestOrange : Color.gray.opacity(0.3), lineWidth: 1)
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
