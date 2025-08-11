//
//  HealthStatsSectionView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct HealthStatsSectionView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("건강 데이터")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }

            VStack(spacing: 8) {
                HealthStatItemView(
                    icon: "figure.walk",
                    iconColor: .orange,
                    title: "걸음 수",
                    value: "6,000보",
                    subtitle: "평균",
                    change: "+12%",
                    changeType: .increase
                )

                HealthStatItemView(
                    icon: "bed.double.fill",
                    iconColor: .blue,
                    title: "수면",
                    value: "7시간 15분",
                    subtitle: "평균",
                    change: "유지",
                    changeType: .stable
                )

                HealthStatItemView(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "명상",
                    value: "주 3회",
                    subtitle: "성공",
                    change: "+1회",
                    changeType: .increase
                )
            }
        }
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
}
