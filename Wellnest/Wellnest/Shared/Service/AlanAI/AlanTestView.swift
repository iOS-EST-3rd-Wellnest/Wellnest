//
//  AlanTestView.swift
//  Wellnest
//
//  Created by junil on 7/31/25.
//

import SwiftUI

struct AlanTestView: View {
    @StateObject private var alanService = AlanAIService()
    @State private var question: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            headerSection
            inputSection
            actionButton
            responseSection
            Spacer()
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
    }

    // MARK: - View Components
    private var headerSection: some View {
        Text("Alan AI")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.top)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("요청을 입력하세요")
                .font(.headline)

            TextField("예: 체중 감량을 위한 4주 계획을 세워줘", text: $question)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(alanService.isLoading)
                .focused($isTextFieldFocused)
        }
        .padding(.horizontal)
    }

    private var actionButton: some View {
        Button(action: {
            isTextFieldFocused = false
            alanService.sendHealthPlanRequest(question)
        }) {
            HStack {
                if alanService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(alanService.isLoading ? "플랜 생성 중..." : "플랜 요청")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(buttonBackgroundColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(question.isEmpty || alanService.isLoading)
        .padding(.horizontal)
    }

    private var buttonBackgroundColor: Color {
        (question.isEmpty || alanService.isLoading) ? Color.gray : Color.blue
    }

    private var responseSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if !alanService.response.isEmpty {
                    successResponseView
                }

                if !alanService.errorMessage.isEmpty {
                    errorResponseView
                }
            }
            .padding(.horizontal)
        }
    }

    private var successResponseView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("맞춤형 플랜:")
                .font(.headline)
                .fontWeight(.bold)

            ImprovedMarkdownTextView(text: alanService.response)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    private var errorResponseView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("오류:")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.red)

            Text(alanService.errorMessage)
                .padding()
                .background(Color(.systemRed).opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(10)
        }
    }
}

#Preview {
    AlanTestView()
}
