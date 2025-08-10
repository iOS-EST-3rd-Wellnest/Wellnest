//
//  VideoView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/7/25.
//

import SwiftUI

struct VideoView: View {
    @ObservedObject var homeVM: HomeViewModel
    
    @Environment(\.sizeCategory) private var sizeCategory   // 다이내믹 타입 대응

    private let videoListTemp = VideoRecommendModel.videoList
    
    // .callout 두 줄 높이
    private var twoLineHeight: CGFloat {
        let base = UIFont.preferredFont(forTextStyle: .callout)
        let scaled = UIFontMetrics(forTextStyle: .callout).scaledFont(for: base)
        return ceil(scaled.lineHeight * 2)
    }
    
    var body: some View {
        HStack(spacing: Spacing.layout * 1.5) {
            //ForEach(homeVM.videoList) { video in
            ForEach(videoListTemp) { video in
                let url = URL(string: "https://www.youtube.com/watch?v=\(video.id)")!
                
                Link(destination: url) {
                    VStack {
                        Group {
                            // 1) 캐시된 이미지가 있으면 사용
                            if let uiImage = homeVM.images[video.id] {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .cornerRadius(CornerRadius.large)
                                    .defaultShadow()
                            }
                            // 2) 아직 없으면 로딩 인디케이터 + 로드 트리거
                            else {
                                Rectangle()
                                    .fill(.clear)
                                    .overlay(
                                        ProgressView()
                                            .task {
                                                await homeVM.loadImage(for: video)
                                            }
                                    )
                            }
                        }
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width - (Spacing.layout * 4))
                        
                        
                        Text(video.title)
                            .multilineTextAlignment(.leading)
                            .font(.callout)
                            .lineLimit(2)
                            .frame(maxWidth: UIScreen.main.bounds.width - (Spacing.layout * 6), minHeight: twoLineHeight, alignment: .topLeading)
                            .padding(.vertical, Spacing.inline)
                    }
                }
                .tint(.black)
            }
        }
        .padding(.horizontal, Spacing.layout * 1.5)
    }
}

#Preview {
    VideoView(homeVM: HomeViewModel())
}
