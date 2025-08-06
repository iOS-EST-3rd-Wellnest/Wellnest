//
//  RawResponseView.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct RawResponseView: View {
    let rawResponse: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI 원본 응답")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("아래 응답에서 JSON 부분을 확인하고 문제를 파악해보세요:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(rawResponse)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("원본 응답")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RawResponseView(rawResponse: "{ \"test\": \"response\" }")
}
