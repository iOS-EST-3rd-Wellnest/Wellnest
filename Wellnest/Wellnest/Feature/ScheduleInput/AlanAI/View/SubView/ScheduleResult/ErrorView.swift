//
//  ErrorView.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct ErrorView: View {
    let errorMessage: String
    let rawResponse: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text("일정 생성중 오류가 발생했습니다\n잠시 후 다시 시도해주세요")
                .font(.callout)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
