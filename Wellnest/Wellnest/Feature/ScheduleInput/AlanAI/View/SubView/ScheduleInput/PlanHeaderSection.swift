//
//  PlanHeaderSection.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct PlanHeaderSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("맞춤 건강 플랜")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text("AI가 당신만의 건강 계획을 만들어드립니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PlanHeaderSection()
        .padding()
}
