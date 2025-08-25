//
//  VideoView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/7/25.
//

import SwiftUI
import SafariServices

struct VideoView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var homeVM: HomeViewModel
    
    @State private var isOnVideo = false
    @State private var videoId: String?
    
    private let placeholderCount = 5
    
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

        HStack(spacing: Spacing.layout * 1.5) {
            if isLoading {
                ForEach(0 ..< placeholderCount, id: \.self) { _ in
                    VideoCardSkeletonView(
                        thumbWidth: thumbWidth,
                        titleWidth: titleWidth,
                        twoLineHeight: twoLineHeight,
                        isLoading: isLoading
                    )
                }
            } else {
                ForEach(homeVM.videoList) { video in
                    VStack {
                        VideoImageView(urlString: video.thumbnail, width: thumbWidth)
                        
                        Text(video.title)
                            .multilineTextAlignment(.leading)
                            .font(.callout)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .lineLimit(2)
                            .frame(maxWidth: titleWidth, minHeight: twoLineHeight, alignment: .topLeading)
                            .padding(.vertical, Spacing.inline)
                    }
                    .onTapGesture {
                        videoId = video.id
                        isOnVideo = true
                    }
                }
            }
        }
        .padding(.horizontal)
        .allowsHitTesting(!isLoading)
        .fullScreenCover(isPresented: $isOnVideo) {
            SafariView(videoId: $videoId)
        }
    }
}

private struct VideoImageView: View {
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
        .task(id: urlString) {
            image = await ImageLoader.shared.load(urlString)
        }
    }
}

private struct VideoCardSkeletonView: View {
    let thumbWidth: CGFloat
    let titleWidth: CGFloat
    let twoLineHeight: CGFloat
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.inline) {
            SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.large))
                .frame(width: thumbWidth, height: thumbWidth * 9 / 16)
            
            SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.medium))
                .frame(width: titleWidth, height: twoLineHeight - 10, alignment: .topLeading)
                .padding(.vertical, Spacing.inline)
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

#Preview {
    VideoView(homeVM: HomeViewModel())
}
