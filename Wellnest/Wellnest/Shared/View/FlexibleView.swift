//
//  FlexibleView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import SwiftUI

/// 유연하게 줄바꿈이 되는 뷰 레이아웃 (예: 태그 리스트)
/// `Collection`을 받아 요소들을 넘치는 경우 자동으로 다음 줄로 배치합니다.
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {

    // MARK: - Properties

    /// 표시할 데이터 컬렉션
    var data: Data

    /// 항목 간의 간격
    var spacing: CGFloat

    /// 수평 정렬 방식
    var alignment: HorizontalAlignment

    /// 각 데이터 항목에 대한 뷰 생성 클로저
    let content: (Data.Element) -> Content

    /// 초기화 메서드
    init(
        data: Data,
        spacing: CGFloat = Spacing.content,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    /// 전체 높이를 계산하기 위한 상태 변수
    @State private var totalHeight = CGFloat.zero

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)  // 실제 항목을 배치하는 내부 메서드 호출
        }
        .frame(height: totalHeight) // 내부에서 측정한 높이만큼 프레임 고정
    }

    // MARK: - Layout Algorithm

    /// 실제 레이아웃을 생성하는 메서드
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero   // 현재 줄의 가로 누적 길이
        var height = CGFloat.zero  // 현재 줄의 세로 위치

        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
                    .padding([.horizontal, .vertical], Spacing.inline)
                    .alignmentGuide(.leading, computeValue: { d in
                        // 다음 항목이 한 줄에 들어가지 못하면 줄 바꿈
                        if abs(width - d.width) > geometry.size.width {
                            width = 0
                            height -= d.height + spacing
                        }

                        let result = width

                        // 마지막 아이템이면 줄바꿈 기준값 초기화
                        if item == Array(data).last {
                            width = 0
                        } else {
                            width -= d.width + spacing
                        }

                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in height })
            }
        }
        .background(viewHeightReader($totalHeight)) // 전체 높이 측정
    }

    // MARK: - View Height 측정용

    /// 내부 레이아웃의 실제 높이를 읽어와 상태에 저장하는 뷰
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geometry.size.height
            }
            return Color.clear
        }
    }
}

#Preview {
//    FlexibleView()
}
