//
//  PreferencesSelectionSection.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat

    init(spacing: CGFloat = 10) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.offsets[index].x, y: bounds.minY + result.offsets[index].y), proposal: .unspecified)
        }
    }
}

struct FlowResult {
    var bounds = CGSize.zero
    var offsets: [CGPoint] = []

    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: x, y: y))
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
        }

        bounds = CGSize(width: maxWidth, height: y + lineHeight)
    }
}

struct PreferencesSelectionSection: View {
    @Binding var selectedPreferences: Set<String>
    let onPreferenceToggle: (String) -> Void

    @StateObject private var userInfoViewModel = UserInfoViewModel()

    private var splitPreferences: [String] {
        var result: [String] = []

        for preference in userInfoViewModel.activityPreferences {
            let splitTitles = preference.title.components(separatedBy: "/")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            result.append(contentsOf: splitTitles)
        }

        return Array(Set(result)).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("선호하는 활동")
                .font(.headline)
                .fontWeight(.semibold)

            FlowLayout(spacing: 10) {
                ForEach(splitPreferences, id: \.self) { preference in
                    PreferenceChip(
                        title: preference,
                        isSelected: selectedPreferences.contains(preference)
                    ) {
                        onPreferenceToggle(preference)
                    }
                }
            }
        }
    }
}

#Preview {
    PreferencesSelectionSection(
        selectedPreferences: .constant(Set(["산책", "요가"])),
        onPreferenceToggle: { _ in }
    )
    .padding()
}
