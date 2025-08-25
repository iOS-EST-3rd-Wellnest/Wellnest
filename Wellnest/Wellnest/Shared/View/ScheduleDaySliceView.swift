//
//  ScheduleDaySliceView.swift
//  Wellnest
//
//  Created by 박동언 on 8/23/25.
//

import SwiftUI

struct ScheduleDaySliceView: View {
    let slice: ScheduleDaySlice

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.content) {
            HStack {
                Image(systemName: "clock.fill")

                if slice.isAllDayForThatDate {
                    Text("하루 종일")
                        .font(.footnote)
                } else if let s = slice.displayStart, let e = slice.displayEnd {
                    Text("\(s.formattedTime) ~ \(e.formattedTime)")
                        .font(.footnote)
                }

                Spacer()

                if slice.item.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.black)
                        .font(.title2)
                }
            }

            HStack {
                Text(slice.item.title)
                    .font(.headline)
                    .bold()

                Spacer()

                if let repeatRule = slice.item.repeatRule {
                    Text(repeatRule)
                        .font(.caption2)
                        .padding(.horizontal, Spacing.content)
                        .background {
                            Capsule().fill(.secondary.opacity(0.3))
                        }
                }
            }
        }
        .padding()
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.scheduleSolid(color: slice.item.backgroundColor))
                .defaultShadow()
        )
    }
}
