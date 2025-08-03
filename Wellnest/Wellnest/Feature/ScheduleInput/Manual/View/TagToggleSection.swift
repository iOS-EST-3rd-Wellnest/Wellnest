//
//  TagToggleSection.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import SwiftUI

struct TagToggleSection<Model: TagModel>: View {
    let title: String
    let tags: [Model]
    @Binding var isOn: Bool
    @Binding var selectedTag: Model?
    let showDetail: Bool
    let detailContent: (() -> AnyView)?

    var body: some View {
        VStack(alignment: .leading) {
            Toggle(title, isOn: $isOn)

            if isOn {
                HStack(spacing: 12) {
                    FlexibleView(data: tags, spacing: Spacing.content, alignment: .leading) { tag in
                        TagView(tag: tag, isSelected: tag == selectedTag)
                            .onTapGesture {
                                selectedTag = tag
                            }
                    }
                }

                if showDetail, let detail = detailContent {
                    detail()
                }
            }
        }
    }
}

protocol TagModel: Identifiable, Hashable {
    var name: String { get }
    static var tags: [Self] { get }
}



