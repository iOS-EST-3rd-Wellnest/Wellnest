//
//  FilledButton.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/3/25.
//

import SwiftUI

struct FilledButton: View {
    private let title: String
    private let disabled: Bool
    private let action: () -> Void
    private let foregroundColor: Color
    private let backgroundColor: Color

    init(title: String,
         disabled: Bool = false,
         foregroundColor: Color = .white,
         backgroundColor: Color = .wellnestOrange,
         action: @escaping () -> Void) {
        self.title = title
        self.disabled = disabled // @Binding 초기화는 언더바로
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)

        }
        .defaultShadow()
        .disabled(disabled)
        .background(
            Capsule()
                .fill(disabled ? Color(.systemGray4) : backgroundColor)
        )
    }
    
}

#Preview {
    FilledButton(title: "저장 하기", disabled: true) {
        print("저장")
    }

    FilledButton(title: "저장 하기", disabled: false) {
        print("저장")
    }
}
