//
//  HomeSkeletonView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/25/25.
//

import SwiftUI

struct GoalSkeletonView: View {
    let height: CGFloat
    var body: some View {
        SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.large))
            .frame(minHeight: height)
            .roundedBorder(cornerRadius: CornerRadius.large)
    }
}

struct RecommendHeaderView: View {
    let title: String
    let isLoading: Bool
    let height: CGFloat
    
    var body: some View {
        HStack {
            if isLoading {
                SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    .frame(width: 150, height: height, alignment: .topLeading)
                    .roundedBorder(cornerRadius: CornerRadius.large)
            } else {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(height: height, alignment: .topLeading)
            }
            
            Spacer()
        }
    }
}

struct RecommendContentSkeletonView: View {
    let category: RecommendCategory
    var body: some View {
        VStack(alignment: .leading ) {
            SkeletonView(shape: .rect(cornerRadius: CornerRadius.large))
                .frame(maxWidth: .infinity, minHeight: category == RecommendCategory.weather ? 100 : 60, alignment: .leading)
                .roundedBorder(cornerRadius: CornerRadius.large)
        }
    }
}

struct VideoiPhoneSkeletonView: View {
    let thumbWidth: CGFloat
    let titleWidth: CGFloat
    let twoLineHeight: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.inline) {
            SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.large))
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: thumbWidth)
                .roundedBorder(cornerRadius: CornerRadius.large)
            
            SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.medium))
                .frame(width: titleWidth, height: twoLineHeight - 10, alignment: .topLeading)
                .padding(.vertical, Spacing.inline)
                .roundedBorder(cornerRadius: CornerRadius.large)
        }
    }
}

struct VideoiPadSkeletonView: View {
    let thumbWidth: CGFloat
    let titleWidth: CGFloat
    let twoLineHeight: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.inline) {
            SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.large))
                .aspectRatio(16/9, contentMode: .fill)
                .frame(maxWidth: thumbWidth)
                .roundedBorder(cornerRadius: CornerRadius.large)
            
            SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.medium))
                .frame(maxWidth: titleWidth, maxHeight: twoLineHeight - 10, alignment: .topLeading)
                .padding(.vertical, Spacing.inline)
                .padding(.trailing, Spacing.layout * 8)
                .roundedBorder(cornerRadius: CornerRadius.large)
        }
    }
}
