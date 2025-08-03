//
//  FilledButton.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/3/25.
//

import SwiftUI

struct FilledButton: View {
    private let title: String
    private let action: () -> Void
    private let foregroundColor: Color
    private let backgroundColor: Color

    init(title: String, action: @escaping () -> Void, foregroundColor: Color = .white, backgroundColor: Color = .blue) {
        self.title = title
        self.action = action
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }

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
