//
//  FilledButton.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/3/25.
//

import SwiftUI

struct FilledButton: View {
    // MARK: - Properties

    /// 버튼에 표시될 텍스트
    private let title: String

    /// 버튼이 눌렸을 때 실행할 액션
    private let action: () -> Void

    /// 버튼 텍스트의 색상 (기본값: white)
    private let foregroundColor: Color

    /// 버튼 배경의 색상 (기본값: blue)
    private let backgroundColor: Color

    // MARK: - Initializer

    /// FilledButton 초기화 메서드
    /// - Parameters:
    ///   - title: 버튼에 표시할 텍스트
    ///   - action: 버튼 탭 시 실행할 클로저
    ///   - foregroundColor: 텍스트 색상 (기본값: white)
    ///   - backgroundColor: 배경 색상 (기본값: blue)
    init(title: String, action: @escaping () -> Void, foregroundColor: Color = .white, backgroundColor: Color = .blue) {
        self.title = title
        self.action = action
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }

    // MARK: - View Body

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(backgroundColor)
                )
        }
    }
    
}

#Preview {
    FilledButton(title: "저장 하기") {
        print("저장")
    }
}
