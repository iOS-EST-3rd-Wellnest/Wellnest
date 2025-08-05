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
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.red)

                Text("오류가 발생했습니다")
                    .font(.headline)
                    .fontWeight(.bold)

                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if !rawResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI 응답 (파싱 실패):")
                            .font(.headline)
                            .fontWeight(.bold)

                        Text(rawResponse)
                            .font(.caption)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ErrorView(
        errorMessage: "JSON 파싱에 실패했습니다.",
        rawResponse: "{ \"invalid\": json }"
    )
}
