//
//  AIInsightCardView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct AIInsightView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: AIInsightViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: AIInsightViewModel())
    }

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large)
            .fill(.wellnestBackgroundCard)
            .frame(minHeight: 80)
            .roundedBorder(cornerRadius: CornerRadius.large)
            .defaultShadow()
            .overlay(alignment: .leading) {
                HStack(spacing: Spacing.content) {
                    Image(systemName: "lightbulb.max.fill")
                        .font(.title2)
                        .foregroundColor(.wellnestOrange)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: Spacing.content) {
                        Text("AI 인사이트")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(viewModel.insightText ?? "")
                            .font(.callout)
                            .fontWeight(.medium)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
            }
    }
}
