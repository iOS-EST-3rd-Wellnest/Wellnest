//
//  QuoteWeatherView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/26/25.
//

import SwiftUI

struct QuoteWeatherView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var homeVM: HomeViewModel
    
    private var oneLineHeight: CGFloat {
        let base = UIFont.preferredFont(forTextStyle: .title2)
        let scaled = UIFontMetrics(forTextStyle: .title2).scaledFont(for: base)
        return ceil(scaled.lineHeight)
    }
    
    private var isQuoteOfTheDay: Bool {
        homeVM.quoteOfTheDay == nil || homeVM.quoteOfTheDay == ""
    }
    
    var body: some View {
        SectionHeaderView(title: "오늘의 한마디", isLoading: isQuoteOfTheDay, height: oneLineHeight)
            .frame(height: oneLineHeight, alignment: .leading)
            .padding(.top, Spacing.layout * 2)
        
        if let quoteOfTheDay = homeVM.quoteOfTheDay, quoteOfTheDay != "" {
            Text(quoteOfTheDay)
                .font(.callout)
                .padding(.horizontal, Spacing.layout * 1.5)
                .padding(.vertical, Spacing.layout)
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                        .roundedBorder(cornerRadius: CornerRadius.large)
                        .defaultShadow()
                )
        } else {
            ContentSkeletonView(category: RecommendCategory.quoteOfTheDay)
        }
        
        SectionHeaderView(title: "날씨", isLoading: homeVM.weatherResponse == nil, height: oneLineHeight)
            .frame(height: oneLineHeight, alignment: .leading)
            .padding(.top, Spacing.content)
        
        if let weatherResponse = homeVM.weatherResponse {
            VStack(alignment: .leading, spacing: Spacing.content) {
                Text("\(weatherResponse.description)")
                    .font(.callout)
                
                HStack {
                    ForEach(weatherResponse.schedules, id:\.self) {
                        Text("\($0)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, Spacing.layout * 1.5)
            .padding(.vertical, Spacing.layout)
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                    .roundedBorder(cornerRadius: CornerRadius.large)
                    .defaultShadow()
            )
        } else {
            ContentSkeletonView(category: RecommendCategory.weather)
        }
    }
}
