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
        return max(50, profileVstackHeight * (UIDevice.current.userInterfaceIdiom == .pad ? 1.5 : 1))
    }
    
    var body: some View {
        HStack(spacing: Spacing.layout) {
            VStack(alignment: .leading, spacing: Spacing.content) {
                Text(homeVM.userInfo?.nickname ?? "")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.wellnestOrange)
                
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
                    .frame(height: imgHeight)
                    .clipShape(RoundedRectangle(cornerRadius: imgHeight / 2))
            } else {
                Image("img_profile")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame( height: imgHeight)
                    .clipShape(RoundedRectangle(cornerRadius: imgHeight / 2))
            }
        }
    }
}
