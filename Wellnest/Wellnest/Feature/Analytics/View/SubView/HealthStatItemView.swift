//
//  HealthStatItemView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct HealthStatItemView: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    let change: String
    let changeType: ChangeType

    enum ChangeType {
        case increase, decrease, stable

        var color: Color {
            switch self {
            case .increase: return .green
            case .decrease: return .red
            case .stable: return .gray
            }
        }

        var icon: String {
            switch self {
            case .increase: return "arrow.up"
            case .decrease: return "arrow.down"
            case .stable: return "minus"
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 아이콘
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 30)

            // 정보
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryTextColor)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // 변화량
            HStack(spacing: 4) {
                Image(systemName: changeType.icon)
                    .font(.caption)
                    .foregroundColor(changeType.color)

                Text(change)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(changeType.color)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(cardBackgroundColor)
        .cornerRadius(8)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.1) : Color(.systemGray6)
    }
}
