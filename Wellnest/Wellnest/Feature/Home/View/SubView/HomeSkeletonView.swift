//
//  HomeSkeletonView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/25/25.
//

import SwiftUI

struct GoalSkeletonView: View {
    var body: some View {
        HStack {
            SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.large))
                .frame(minHeight: 180)
            
            SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.large))
                .frame(minHeight: 180)
        }
    }
}

struct SectionHeaderView: View {
    let title: String
    let isLoading: Bool
    let height: CGFloat
    
    var body: some View {
        HStack {
            
            if isLoading {
                SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    .frame(width: 150, height: height, alignment: .topLeading)
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

struct ContentSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading ) {
            SkeletonView(shape: .rect(cornerRadius: CornerRadius.large))
                .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        }
    }
}

struct VideoCardSkeletonView: View {
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
