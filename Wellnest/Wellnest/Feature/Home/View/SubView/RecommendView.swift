//
//  RecommendView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/5/25.
//

import SwiftUI
import SkeletonUI

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
                SectionHeader(title: "오늘의 한마디", isLoading: isQuoteOfTheDay, height: oneLineHeight)
                    .frame(height: oneLineHeight, alignment: .leading)
                
                if let quoteOfTheDay = homeVM.quoteOfTheDay, quoteOfTheDay != "" {
                    Text(quoteOfTheDay)
                        .font(.callout)
                        .padding(.horizontal, Spacing.layout * 1.5)
                        .padding(.vertical, Spacing.layout)
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.large)
                                .fill(colorScheme == .dark ? Color(.gray) : .white)
                                .defaultShadow()
                        )
                } else {
                    SkeletonView()
                }
                
                SectionHeader(title: "날씨", isLoading: homeVM.weatherResponse == nil, height: oneLineHeight)
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
                            .fill(colorScheme == .dark ? Color(.gray) : .white)
                            .defaultShadow()
                    )
                } else {
                    SkeletonView()
                }
                
                SectionHeader(title: "추천 영상", isLoading: homeVM.videoList.isEmpty, height: oneLineHeight)
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

private struct SectionHeader: View {
    let title: String
    let isLoading: Bool
    let height: CGFloat
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .bold()
                .frame(height: height, alignment: .topLeading)
                .skeleton(with: isLoading,
                          size: CGSize(width: 150, height: height),
                          animation: .none,
                          shape: .rounded(.radius(CornerRadius.medium, style: .circular)))
            Spacer()
        }
    }
}

private struct SkeletonView: View {
    var body: some View {
        VStack(alignment: .leading ) {
            Rectangle()
                .skeleton(with: true, shape: .rounded(.radius(CornerRadius.medium, style: .circular)))
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
        }
    }
}
