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
    
    var body: some View {
        VStack {
            Group {
                if homeVM.quoteOfTheDay == nil || homeVM.quoteOfTheDay == "" {
                    SkeletonView(oneLineHeight: oneLineHeight)
                } else {
                    HStack {
                        Text("오늘의 한마디")
                            .font(.title2)
                            .bold()
                            .frame(minHeight: oneLineHeight)
                        
                        Spacer()
                    }
                    
                    Text(homeVM.quoteOfTheDay ?? "")
                        .font(.callout)
                        .padding(.horizontal, Spacing.layout * 1.5)
                        .padding(.vertical, Spacing.layout)
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.large)
                                .fill(colorScheme == .dark ? Color(.gray) : .white)
                                .defaultShadow()
                        )
                }
                
                if homeVM.weatherResponse == nil {
                    SkeletonView(oneLineHeight: oneLineHeight)
                        .padding(.top, Spacing.layout)
                } else {
                    HStack {
                        Text("날씨")
                            .font(.title2)
                            .bold()
                            .frame(minHeight: oneLineHeight)
                            .padding(.top, Spacing.layout)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.content) {
                        if let weatherResponse = homeVM.weatherResponse {
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
                    }
                    .padding(.horizontal, Spacing.layout * 1.5)
                    .padding(.vertical, Spacing.layout)
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(colorScheme == .dark ? Color(.gray) : .white)
                            .defaultShadow()
                    )
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading) {
                if homeVM.videoList.isEmpty {
                    Rectangle()
                        .skeleton(with: true, shape: .rounded(.radius(CornerRadius.medium, style: .circular)))
                        .frame(width: 130)
                        .frame(minHeight: oneLineHeight, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, Spacing.layout)
                } else {
                    Text("추천 영상")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                        .padding(.top, Spacing.layout)

                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    VideoView(homeVM: homeVM)
                }
            }
        }
    }
}

#Preview {
    RecommendView(homeVM: HomeViewModel())
}

private struct SkeletonView: View {
    let oneLineHeight: CGFloat
    var body: some View {
        VStack(alignment: .leading ) {
            Rectangle()
                .skeleton(with: true, shape: .rounded(.radius(CornerRadius.medium, style: .circular)))
                .frame(width: 130)
                .frame(minHeight: oneLineHeight, alignment: .leading)
            
            Rectangle()
                .skeleton(with: true, shape: .rounded(.radius(CornerRadius.medium, style: .circular)))
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
        }
    }
}
