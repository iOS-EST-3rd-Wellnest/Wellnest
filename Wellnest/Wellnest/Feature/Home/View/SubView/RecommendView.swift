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
            HStack {
                Text("오늘의 한마디")
                    .font(.title2)
                    .bold()
                    .padding(Spacing.content)
                
                Spacer()
            }
            
            Text("휴식도 하나의 전략입니다. 잠시 멈추어 숨을 고르고 다시 시작하세요.")
                .font(.callout)
                .padding()
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(Color(.systemGray6))
                        .padding(.horizontal, Spacing.inline)
                )
            
            HStack {
                Text("날씨")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal, Spacing.content)
                    .padding(.top, Spacing.layout)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("오늘 날씨는 비가 내리네요.\n실내에서 할 수 있는 일정을 추천해드릴게요.")
                        .font(.callout)
                        .padding(.horizontal, Spacing.content)
                    
                    Button {
                        
                    } label: {
                        Text("· 헬스장")
                            .font(.footnote)
                            .foregroundStyle(.blue)
                            .padding(.vertical, Spacing.inline)
                            .padding(.horizontal)
                    }
                    
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(Color(.systemGray6))
                    .frame(width: UIScreen.main.bounds.width - (Spacing.layout * 4))
            )
            
            HStack {
                Text("추천 영상 🎬")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal, Spacing.content)
                    .padding(.top, Spacing.layout)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                VideoView(homeVM: homeVM)
            }
            .padding(.horizontal, Spacing.inline)
        }
    }
}

#Preview {
    RecommendView(homeVM: HomeViewModel())
}
