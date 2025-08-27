//
//  TagToggleSection.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import SwiftUI

// 기본: Detail 뷰 제네릭
struct TagToggleSection<Model: TagModel & Equatable, Detail: View>: View {
    let title: String
    let tags: [Model]
    @Binding var isOn: Bool
    @Binding var selectedTag: Model?

    let showDetail: Bool
    private let detailContent: () -> Detail
    var onTagTap: ((Model) -> Void)? = nil

    init(
        title: String,
        tags: [Model],
        isOn: Binding<Bool>,
        selectedTag: Binding<Model?>,
        showDetail: Bool = false,
        onTagTap: ((Model) -> Void)? = nil,
        @ViewBuilder detailContent: @escaping () -> Detail
    ) {
        self.title = title
        self.tags = tags
        self._isOn = isOn
        self._selectedTag = selectedTag
        self.showDetail = showDetail
        self.onTagTap = onTagTap
        self.detailContent = detailContent
    }

    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $isOn) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .tint(.wellnestOrange)
            if isOn {
                HStack {
                    FlexibleView(data: tags, spacing: Spacing.content, alignment: .leading) { tag in
                        TagView(tag: tag, isSelected: tag == selectedTag)
                            .onTapGesture {
                                selectedTag = tag
                                onTagTap?(tag)
                            }
                    }
                }

                if showDetail {
                    detailContent()
                }
            }
        }
    }
}

// EmptyView를 쓰는 편의 생성자 (detailContent 생략 가능)
extension TagToggleSection where Detail == EmptyView {
    init(
        title: String,
        tags: [Model],
        isOn: Binding<Bool>,
        selectedTag: Binding<Model?>,
        showDetail: Bool = false,
        onTagTap: ((Model) -> Void)? = nil
    ) {
        self.init(
            title: title,
            tags: tags,
            isOn: isOn,
            selectedTag: selectedTag,
            showDetail: showDetail,
            onTagTap: onTagTap,
            detailContent: { EmptyView() }
        )
    }
}

protocol TagModel: Identifiable, Hashable, Equatable {
    var name: String { get }
    static var tags: [Self] { get }
}

extension TagModel {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
