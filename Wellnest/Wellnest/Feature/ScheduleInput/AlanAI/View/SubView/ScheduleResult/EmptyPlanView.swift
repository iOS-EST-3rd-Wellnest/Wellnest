//
//  EmptyPlanView.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct EmptyPlanView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("플랜을 생성할 수 없습니다")
                .font(.headline)
                .fontWeight(.bold)

            Text("다시 시도해주세요")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    EmptyPlanView()
}
