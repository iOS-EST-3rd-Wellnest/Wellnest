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
    
    private let videoListTemp = VideoRecommendModel.videoList
    
    var body: some View {
        VStack {
            Group {
                HStack {
                    Text("오늘의 한마디")
                        .font(.title2)
                        .bold()
                    
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
                
                HStack {
                    Text("날씨")
                        .font(.title2)
                        .bold()
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
                
                HStack {
                    Text("추천 영상")
                        .font(.title2)
                        .bold()
                        .padding(.top, Spacing.layout)
                    
                    Spacer()
                }
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
