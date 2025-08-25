//
//  RecommendView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/5/25.
//

import SwiftUI

struct RecommendView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var homeVM: HomeViewModel
    
    // .title 한줄 높이
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
            Group {
                SectionHeaderView(title: "오늘의 한마디", isLoading: isQuoteOfTheDay, height: oneLineHeight)
                    .frame(height: oneLineHeight, alignment: .leading)
                
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
                    ContentSkeletonView()
                }
                
                SectionHeaderView(title: "날씨", isLoading: homeVM.weatherResponse == nil, height: oneLineHeight)
                    .frame(height: oneLineHeight, alignment: .leading)
                    .padding(.top, Spacing.layout)
                
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
                    ContentSkeletonView()
                }
                
                SectionHeaderView(title: "추천 영상", isLoading: homeVM.videoList.isEmpty, height: oneLineHeight)
                    .frame(height: oneLineHeight)
                    .padding(.top, Spacing.layout)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                VideoView(homeVM: homeVM)
            }
        }
    }
}

#Preview {
    RecommendView(homeVM: HomeViewModel())
}
