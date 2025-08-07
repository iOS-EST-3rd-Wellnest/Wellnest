//
//  VideoView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/7/25.
//

import SwiftUI

struct VideoView: View {
    @ObservedObject var homeVM: HomeViewModel
    
    let videoListTemp = VideoRecommendModel.videoList
    
    var body: some View {
        HStack(spacing: 0) {
            //ForEach(homeVM.videoList) { video in
            ForEach(videoListTemp) { video in
                let url = URL(string: "https://www.youtube.com/watch?v=\(video.id)")!
                
                Link(destination: url) {
                    VStack {
                        Spacer()

                        Group {
                            // 1) 캐시된 이미지가 있으면 사용
                            if let uiImage = homeVM.images[video.id] {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(CornerRadius.large)
                                    .defaultShadow()
                            }
                            // 2) 아직 없으면 로딩 인디케이터 + 로드 트리거
                            else {
                                ProgressView()
                                    .task {
                                        await homeVM.loadImage(for: video)
                                    }
                            }
                            
                        }
                        .frame(width: UIScreen.main.bounds.width - (Spacing.layout * 7))
                        
                        Spacer()
                        
                        Text(video.title)
                            .font(.callout)
                            .lineLimit(1)
                            .frame(maxWidth: UIScreen.main.bounds.width - (Spacing.layout * 10))
                            .padding(.vertical, Spacing.inline)
                    }
                    
                }
                .tint(.black)
                .padding(.horizontal, Spacing.layout)
            }
        }
    }
}

#Preview {
    VideoView(homeVM: HomeViewModel())
}
