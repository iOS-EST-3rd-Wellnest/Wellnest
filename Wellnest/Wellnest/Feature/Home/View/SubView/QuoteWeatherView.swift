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
    
    private let isDevicePad = UIDevice.current.userInterfaceIdiom == .pad
    
    private var oneLineHeight: CGFloat {
        let base = UIFont.preferredFont(forTextStyle: .title2)
        let scaled = UIFontMetrics(forTextStyle: .title2).scaledFont(for: base)
        return ceil(scaled.lineHeight)
    }
    
    private var isQuoteOfTheDay: Bool {
        homeVM.quoteOfTheDay == nil || homeVM.quoteOfTheDay == ""
    }
    
    var body: some View {
        VStack {
            VStack(spacing: Spacing.content) {
                RecommendHeaderView(title: "오늘의 한마디", isLoading: isQuoteOfTheDay, height: oneLineHeight)
                
                if let quoteOfTheDay = homeVM.quoteOfTheDay, quoteOfTheDay != "" {
                    Text(quoteOfTheDay)
                        .font(.callout)
                        .padding(.horizontal, Spacing.layout * 1.5)
                        .padding(.vertical, Spacing.layout)
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.large)
                                .fill(.wellnestBackgroundCard)
                                .roundedBorder(cornerRadius: CornerRadius.large)
                                .defaultShadow()
                        )
                } else {
                    RecommendContentSkeletonView(category: RecommendCategory.quoteOfTheDay)
                }
            }
            .padding(.top, isDevicePad ? Spacing.layout * 2 : Spacing.layout)
            
            VStack(spacing: Spacing.content) {
                RecommendHeaderView(title: "날씨", isLoading: homeVM.weatherResponse == nil, height: oneLineHeight)
                
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
                            .fill(.wellnestBackgroundCard)
                            .roundedBorder(cornerRadius: CornerRadius.large)
                            .defaultShadow()
                    )
                } else {
                    RecommendContentSkeletonView(category: RecommendCategory.weather)
                }
            }
            .padding(.top, Spacing.content)
        }
    }
}
