//
//  VideoCardView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/7/25.
//

import SwiftUI
import SafariServices

struct VideoiPhoneCardView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var homeVM: HomeViewModel
    @State private var isOnVideo = false
    @State private var videoId: String?
    
    private let placeholderCount = 10
    
    // .callout 두 줄 높이
    private var twoLineHeight: CGFloat {
        let base = UIFont.preferredFont(forTextStyle: .callout)
        let scaled = UIFontMetrics(forTextStyle: .callout).scaledFont(for: base)
        return ceil(scaled.lineHeight * 2)
    }
    
    var body: some View {
        let thumbWidth = UIScreen.main.bounds.width - (Spacing.layout * 4)
        let titleWidth = UIScreen.main.bounds.width - (Spacing.layout * 6)
        let isLoading = homeVM.videoList.isEmpty

        Group {
            if homeVM.videoList.isEmpty {
                ForEach(0 ..< placeholderCount, id: \.self) { _ in
                    VideoiPhoneSkeletonView(
                        thumbWidth: thumbWidth,
                        titleWidth: titleWidth,
                        twoLineHeight: twoLineHeight,
                    )
                }
            } else {
                ForEach(homeVM.videoList) { video in
                    VStack {
                        VideoImageView(urlString: video.thumbnail)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: thumbWidth)
                            .clipped()
                            .cornerRadius(CornerRadius.large)
                        
                        Text(video.title)
                            .font(.callout)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .lineLimit(2)
                            .frame(maxWidth: titleWidth, minHeight: twoLineHeight, alignment: .topLeading)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, Spacing.inline)
                    }
                    .onTapGesture {
                        videoId = video.id
                        isOnVideo = true
                    }
                }
            }
        }
        .allowsHitTesting(!isLoading)
        .fullScreenCover(isPresented: $isOnVideo) {
            SafariView(videoId: $videoId)
        }
    }
}

struct VideoiPadCardView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var homeVM: HomeViewModel
    @State private var isOnVideo = false
    @State private var videoId: String?
    
    private let placeholderCount = 10
    
    private var twoLineHeight: CGFloat {
        let base = UIFont.preferredFont(forTextStyle: .callout)
        let scaled = UIFontMetrics(forTextStyle: .callout).scaledFont(for: base)
        return ceil(scaled.lineHeight * 2.5)
    }

    var body: some View {
        let isLoading = homeVM.videoList.isEmpty
        
        Group {
            if isLoading {
                ForEach(0 ..< placeholderCount, id: \.self) { _ in
                    VideoiPadSkeletonView(thumbWidth: .infinity, titleWidth: .infinity, twoLineHeight: twoLineHeight)
                        .padding(.bottom)
                }
            } else {
                ForEach(homeVM.videoList) { video in
                    VStack {
                        VideoImageView(urlString: video.thumbnail)
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(CornerRadius.large)
                        
                        Text(video.title)
                            .font(.body)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, minHeight: twoLineHeight, alignment: .topLeading)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, Spacing.inline)
                            .padding(.horizontal, Spacing.layout * 1.5)
                    }
                    .onTapGesture {
                        videoId = video.id
                        isOnVideo = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isOnVideo) {
            SafariView(videoId: $videoId)
        }
    }
}


private struct VideoImageView: View {
    @State private var image: UIImage?
    
    let urlString: String

    var body: some View {
        ZStack {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.large))
            }
        }
        .task(id: urlString) {
            image = await ImageLoader.shared.load(urlString)
        }
    }
}

private struct SafariView: UIViewControllerRepresentable {
    @Binding var videoId: String?
    
    private var url: URL {
        URL(string: "https://www.youtube.com/watch?v=\(videoId ?? "")")!
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        let safariController = SFSafariViewController(url: url)
        safariController.dismissButtonStyle = .close
        safariController.preferredBarTintColor = .systemBackground
        safariController.preferredControlTintColor = .wellnestOrange
        
        return safariController
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) { }
}

