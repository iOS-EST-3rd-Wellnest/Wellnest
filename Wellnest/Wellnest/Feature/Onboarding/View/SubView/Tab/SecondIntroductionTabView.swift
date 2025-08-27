//
//  SecondIntroductionTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct SecondIntroductionTabView: View {
    @State private var showSections = [false, false, false]

    @Binding var currentPage: Int
    @Binding var title: String

    let isIPad = OnboardingCardLayout.isIPad

    var body: some View {
        VStack(spacing: isIPad ? 180 : 70) {
            if showSections[0] {
                HStack {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("하루 계획,")
                            HStack {
                                Text("이제 AI에게 맡기세요")
                                Image("secondIntroAI")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: isIPad ? 43 : 30)
                            }
                        }
                        .font(isIPad ? .system(size: 43) : .title)
                        .fontWeight(.semibold)
                        .padding(.bottom, Spacing.content)

                        VStack(alignment: .leading) {
                            Text("바쁜 하루 속에서도, 운동부터 휴식까지")
                            Text("당신에게 꼭 맞는 일정을 생성해줘요")
                        }
                        .font(isIPad ? .title2 : .body)
                        .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .opacity(showSections[0] ? 1 : 0)
                .blur(radius: showSections[0] ? 0 : 10)
                .animation(.easeOut(duration: 0.7), value: showSections[0])
            }

            if showSections[1] {
                HStack {
                    Spacer()

                    VStack(alignment: .trailing) {
                        VStack(alignment: .trailing) {
                            HStack {
                                Image("secondIntroRecommand")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: isIPad ? 48 : 35)
                                    .padding(.trailing, isIPad ? Spacing.inline : nil)
                                Text("당신을 위한 맞춤 추천")
                            }
                        }
                        .font(isIPad ? .system(size: 43) : .title)
                        .fontWeight(.semibold)
                        .padding(.bottom, Spacing.content)

                        VStack(alignment: .trailing) {
                            Text("나이, 신체 정보, 라이프스타일 등을 기반으로")
                            Text("가장 알맞은 영상과 활동을 제안해줘요")
                        }
                        .font(isIPad ? .title2 : .body)
                        .foregroundColor(.secondary)
                    }
                }
                .opacity(showSections[1] ? 1 : 0)
                .blur(radius: showSections[1] ? 0 : 10)
                .animation(.easeOut(duration: 0.7), value: showSections[1])
            }

            if showSections[2] {
                HStack {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("오늘의 나보다")
                            HStack {
                                Text("더 건강한 내일을 위해")
                                Image("secondIntroGrowth")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: isIPad ? 43 : 30)
                            }
                        }
                        .font(isIPad ? .system(size: 43) : .title)
                        .fontWeight(.semibold)
                        .padding(.bottom, Spacing.content)

                        VStack(alignment: .leading) {
                            Text("웰니스 목표를 세우고")
                            Text("작은 성취를 쌓아가며 꾸준히 성장해보세요")
                        }
                        .font(isIPad ? .title2 : .body)
                        .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .opacity(showSections[2] ? 1 : 0)
                .blur(radius: showSections[2] ? 0 : 10)
                .animation(.easeOut(duration: 0.7), value: showSections[2])
            }
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            for i in 0..<showSections.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.8) {
                    withAnimation {
                        showSections[i] = true
                    }
                }
            }
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
