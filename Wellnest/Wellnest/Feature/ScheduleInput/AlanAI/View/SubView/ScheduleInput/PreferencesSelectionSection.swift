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

    @StateObject private var userInfoViewModel = UserInfoViewModel()

    private var splitPreferences: [String] {
        var result: [String] = []

        for preference in userInfoViewModel.activityPreferences {
            let splitTitles = preference.title.components(separatedBy: "/")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0 != "기타" }

            result.append(contentsOf: splitTitles)
        }

        let uniqueResult = Array(Set(result))

        let withoutSpecialNone = uniqueResult.filter { $0 != "특별히 없음" }.sorted()
        let withSpecialNone = uniqueResult.contains("특별히 없음") ? withoutSpecialNone + ["특별히 없음"] : withoutSpecialNone

        return withSpecialNone
    }

    private func getUserStoredPreferences() -> Set<String> {
        guard let userEntity = userInfoViewModel.userEntity else {
            return Set<String>()
        }

        var storedPreferences: Set<String> = Set()

        if let activityPreferencesString = userEntity.activityPreferences {
            let preferences = activityPreferencesString.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            for preference in preferences {
                let splitTitles = preference.components(separatedBy: "/")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty && $0 != "기타" }

                storedPreferences.formUnion(splitTitles)
            }
        }

        return storedPreferences
    }

    private func handlePreferenceToggle(_ preference: String) {
        if preference == "특별히 없음" {
            if selectedPreferences.contains("특별히 없음") {
                // "특별히 없음"이 이미 선택되어 있으면 해제
                selectedPreferences.remove("특별히 없음")
            } else {
                // "특별히 없음"을 선택하면 다른 모든 항목 해제
                selectedPreferences.removeAll()
                selectedPreferences.insert("특별히 없음")
            }
        } else {
            // 다른 항목을 선택할 때
            if selectedPreferences.contains("특별히 없음") {
                selectedPreferences.remove("특별히 없음")
            }

            if selectedPreferences.contains(preference) {
                selectedPreferences.remove(preference)
            } else {
                selectedPreferences.insert(preference)
            }
        }
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
                        handlePreferenceToggle(preference)
                    }
                }
            }
        }
        .onAppear {
            let storedPreferences = getUserStoredPreferences()
            selectedPreferences.formUnion(storedPreferences)
        }
        .onChange(of: userInfoViewModel.userEntity) { _ in
            let storedPreferences = getUserStoredPreferences()
            selectedPreferences.formUnion(storedPreferences)
        }
    }
}

#Preview {
    PreferencesSelectionSection(
        selectedPreferences: .constant(Set(["요가"]))
    )
    .padding()
}
