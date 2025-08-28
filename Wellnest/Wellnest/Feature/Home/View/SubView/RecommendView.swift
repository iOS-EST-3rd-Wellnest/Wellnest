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
    
    private var isDevicePad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        VStack {
            QuoteWeatherView(homeVM: homeVM)
                .padding(.horizontal)
            
            VStack(spacing: Spacing.content) {
                RecommendHeaderView(title: "추천 영상", isLoading: homeVM.videoList.isEmpty, height: oneLineHeight)
                        .padding(.horizontal)
                
                if isDevicePad {
                    let columns = [GridItem(.flexible(), spacing: Spacing.layout * 2), GridItem(.flexible(), spacing: Spacing.layout * 2)]
                    
                    LazyVGrid(columns: columns, spacing: Spacing.layout * 2) {
                        VideoiPadCardView(homeVM: homeVM)
                    }
                    .padding(.horizontal)
                    .if(homeVM.videoList.isEmpty) {
                        $0.padding(.top, Spacing.layout)
                    }
                    
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.layout * 1.5) {
                            VideoiPhoneCardView(homeVM: homeVM)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top, Spacing.content)
        }
    }
}
