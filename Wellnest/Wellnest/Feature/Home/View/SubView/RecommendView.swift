//
//  RecommendView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/5/25.
//

import SwiftUI

struct RecommendView: View {
    @ObservedObject var homeVM: HomeViewModel
    
    let videoListTemp = VideoRecommendModel.videoList
    
    var body: some View {
        VStack {
            Group {
                HStack {
                    Text("오늘의 한마디")
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                }
                
                Text("깊은 명상은 마음의 평화를, 충분한 수면은 활기찬 내일을 선사합니다")
                    .font(.callout)
                    .padding(.horizontal, Spacing.layout * 1.5)
                    .padding(.vertical, Spacing.layout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(Color(.systemGray6))
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
                    Group {
                        Text("오늘 날씨는 비가 내리네요.\n실내에서 할 수 있는 일정을 추천해드릴게요.")
                            .font(.callout)
                        
                        Text(" #헬스장")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, Spacing.layout * 1.5)
                .padding(.vertical, Spacing.layout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(Color(.systemGray6))
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
