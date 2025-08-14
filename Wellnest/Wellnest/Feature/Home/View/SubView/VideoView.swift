//
//  VideoView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/7/25.
//

import SwiftUI

struct VideoView: View {
    @ObservedObject var homeVM: HomeViewModel
    
    @State private var uiImage: UIImage?

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
                let thumbWidth = UIScreen.main.bounds.width - (Spacing.layout * 4)
                
                Link(destination: url) {
                    VStack {
                        VideoImageView(urlString: video.thumbnail, width: thumbWidth)
                        
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
        .padding(.horizontal)
    }
}

struct VideoImageView: View {
    let urlString: String
    let width: CGFloat

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .overlay(ProgressView())
            }
        }
        .aspectRatio(16/9, contentMode: .fill)
        .frame(width: width)
        .clipped()
        .cornerRadius(CornerRadius.large)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .task(id: urlString) {
            image = await ImageLoader.shared.load(urlString)
        }
    }
}

#Preview {
    VideoView(homeVM: HomeViewModel())
}
