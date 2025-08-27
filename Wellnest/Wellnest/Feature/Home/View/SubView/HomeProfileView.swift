//
//  HomeProfileView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/26/25.
//

import SwiftUI

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct HomeProfileView: View {
    @ObservedObject var homeVM: HomeViewModel
    @State private var profileVstackHeight: CGFloat = .zero
    
    private var imgHeight: CGFloat {
        return max(50, profileVstackHeight)
    }
    
    private var footnoteLineHeight: CGFloat {
        let base = UIFont.preferredFont(forTextStyle: .footnote)
        let scaled = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: base)
        return ceil(scaled.lineHeight * 1.5)
    }
    
    var body: some View {
        HStack(spacing: Spacing.layout) {
            VStack(alignment: .leading, spacing: Spacing.content) {
                Text(homeVM.userInfo?.nickname ?? "")
                    .font(.title2)
                    .bold()
                
                if homeVM.hashtagList.isEmpty {
                    if let userInfo = homeVM.userInfo {
                        Text("#\(userInfo.ageRange ?? "")")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack {
                        ForEach(homeVM.hashtagList, id: \.self) {
                            Text("\($0)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .background(
                GeometryReader { profileGeometry in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: profileGeometry.size.height)
                }
            )
            .onPreferenceChange(SizePreferenceKey.self) { newValue in
                guard abs(newValue - profileVstackHeight) > 0.5 else { return }
                DispatchQueue.main.async {
                    
                    profileVstackHeight = newValue
                }
            }
            
            Spacer()
            
            if let data = homeVM.userInfo?.profileImage, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: imgHeight, height: imgHeight)
                    .clipShape(RoundedRectangle(cornerRadius: imgHeight / 2))
            } else {
                Image("img_profile")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: imgHeight, height: imgHeight)
                    .clipShape(RoundedRectangle(cornerRadius: imgHeight / 2))
            }
        }
    }
}
