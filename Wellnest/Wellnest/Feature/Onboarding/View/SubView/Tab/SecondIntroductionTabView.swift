//
//  SecondIntroductionTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct SecondIntroductionTabView: View {
    @Binding var currentPage: Int
    @Binding var title: String

    var body: some View {
        VStack {
//            Image("secondIntroduction")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 200)

            HStack {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("하루 계획,")
                        Text("이제 AI에게 맡기세요")
                    }
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 70)
                    .padding(.bottom, Spacing.content)

                    VStack(alignment: .leading) {
                        Text("바쁜 하루 속에서도, 운동부터 휴식까지")
                        Text("당신에게 꼭 맞는 일정을 생성해줘요")
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.leading, 30)

                Spacer()
            }

            HStack {
                Spacer()

                VStack(alignment: .trailing) {
                    VStack(alignment: .trailing) {
                        Text("당신을 위한 맞춤 추천")
                    }
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 70)
                    .padding(.bottom, Spacing.content)

                    VStack(alignment: .trailing) {
                        Text("나이, 신체 정보, 라이프스타일 등을 기반으로")
                        Text("가장 알맞은 영상과 활동을 제안해줘요")
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.trailing, 30)
            }

            HStack {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("오늘의 나보다")
                        Text("더 건강한 내일을 위해")
                    }
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 70)
                    .padding(.bottom, Spacing.content)

                    VStack(alignment: .leading) {
                        Text("웰니스 목표를 세우고")
                        Text("작은 성취를 쌓아가며 꾸준히 성장해보세요")
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.leading, 30)

                Spacer()
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .safeAreaInset(edge: .bottom) {
            OnboardingButton(
                title: "다음",
                isDisabled: false,
                action: {
                    withAnimation { currentPage += 1 }
                },
                currentPage: $currentPage
            )
        }
        .onAppear {
            title = ""
        }
    }
}

#Preview {
    Preview()
}

private struct Preview: View {
    @State private var currentPage = 0
    @State private var title = "앱 소개"

    var body: some View {
        SecondIntroductionTabView(currentPage: $currentPage, title: $title)
    }
}
