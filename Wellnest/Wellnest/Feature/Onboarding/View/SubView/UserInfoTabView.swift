//
//  UserInfoTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct UserInfoTabView: View {
    @Binding var currentPage: Int

    @State private var nickname: String = ""

    @State private var selectedAge = ""
    let ageOptions = ["10대", "20대", "30대", "40대", "50대", "60대 이상"]

    @State var selectedGender = ""
    var genderOptions = ["여자", "남자"]

    @State private var height: Double?
//    @State private var selectedHeight = ""
//    let heightOptions = ["140대 이하", "150대", "160대", "170대", "180대", "190대 이상"]

    @State private var weight: Double?
//    @State private var selectedWeight = ""
//    let weightOptions = ["20kg대 이하", "30kg대", "40kg대", "50kg대", "60kg대", "70kg대", "80kg대", "90kg대", "100kg대 이상"]

    var body: some View {
        VStack {
            OnboardingTitle(title: "사용자 정보", description: "당신의 정보를 알려주시면 그에 맞게 루틴을 추천해줄게요.")

            VStack {
                HStack {
                    Text("* 필수항목")
                        .font(.caption2)
                    Spacer()
                }
                .padding(.horizontal, Spacing.content)
                .padding(.bottom, Spacing.inline)

                HStack {
                    UserInfoSectionTitle(title: "닉네임 *")

                    // TODO: 5글자 이하 제한 추가
                    TextField(
                        "",
                        text: $nickname,
                        prompt: Text("닉네임을 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    )
                    .padding(.horizontal)
                    .padding(.leading, 10)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(.customSecondary)
                .cornerRadius(CornerRadius.large)
                .padding(.bottom, Spacing.content)

                HStack {
                    UserInfoSectionTitle(title: "연령대 *")

                    Menu {
                        ForEach(ageOptions, id: \.self) { age in
                            Button(action: {
                                selectedAge = age
                            }) {
                                Text(age)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedAge.isEmpty ? "연령대를 선택해주세요." : selectedAge)
                                .foregroundColor(selectedAge.isEmpty ? .gray : .primary)
                                .font(selectedAge.isEmpty ? .footnote : .body)

                            Spacer()

                            // TODO: 메뉴 클릭 시 chevron.up으로 바뀌는 것도 좋을 것 같음
                            Image(systemName: "chevron.down")
                                .foregroundColor(.primary)
                                .imageScale(.small)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .padding(.leading, 10)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(.customSecondary)
                .cornerRadius(CornerRadius.large)
                .padding(.bottom, Spacing.content)

                HStack {
                    UserInfoSectionTitle(title: "성별 *")

                    // TODO: 피커 목록 폰트 크기 바디로 동일하게 바꾸기
                    Picker("", selection: $selectedGender) {
                        ForEach(genderOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .padding(.leading, 20)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(.customSecondary)
                .cornerRadius(CornerRadius.large)
                .padding(.bottom, Spacing.content)

//                HStack {
//                    UserInfoSectionTitle(title: "키")
//
//                    Menu {
//                        ForEach(heightOptions, id: \.self) { height in
//                            Button(action: {
//                                selectedHeight = height
//                            }) {
//                                Text(height)
//                            }
//                        }
//                    } label: {
//                        HStack {
//                            Text(selectedHeight.isEmpty ? "키를 선택해주세요." : selectedHeight)
//                                .foregroundColor(selectedHeight.isEmpty ? .gray : .primary)
//                                .font(selectedHeight.isEmpty ? .footnote : .body)
//
//                            Spacer()
//
//                            Image(systemName: "chevron.down")
//                                .foregroundColor(.primary)
//                                .imageScale(.small)
//                        }
//                        .frame(maxWidth: .infinity)
//                    }
//                    .padding(.trailing)
//                    .padding(.leading, 60)
//                }
//                .frame(maxWidth: .infinity)
//                .frame(height: 58)
//                .background(.customSecondary)
//                .cornerRadius(CornerRadius.large)
//                .padding(.bottom, Spacing.content)

                HStack {
                    UserInfoSectionTitle(title: "키")

                    // TODO: 입력 제한 추가
                    TextField(
                        "",
                        text: Binding(
                            get: {
                                if let height = height {
                                    return String(format: "%.0f", height)
                                } else {
                                    return ""
                                }
                            },
                            set: { newValue in
                                if let value = Double(newValue) {
                                    height = value
                                } else {
                                    height = nil
                                }
                            }
                        ),
                        prompt: Text("키를 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    )
                    .keyboardType(.decimalPad)
                    .padding(.horizontal)
                    .padding(.leading, 42)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(.customSecondary)
                .cornerRadius(CornerRadius.large)
                .padding(.bottom, Spacing.content)

//                HStack {
//                    UserInfoSectionTitle(title: "몸무게")
//
//                    Menu {
//                        ForEach(weightOptions, id: \.self) { weight in
//                            Button(action: {
//                                selectedWeight = weight
//                            }) {
//                                Text(weight)
//                            }
//                        }
//                    } label: {
//                        HStack {
//                            Text(selectedWeight.isEmpty ? "몸무게를 선택해주세요." : selectedWeight)
//                                .foregroundColor(selectedWeight.isEmpty ? .gray : .primary)
//                                .font(selectedWeight.isEmpty ? .footnote : .body)
//
//                            Spacer()
//
//                            Image(systemName: "chevron.down")
//                                .foregroundColor(.primary)
//                                .imageScale(.small)
//                        }
//                        .frame(maxWidth: .infinity)
//                    }
//                    .padding(.trailing)
//                    .padding(.leading, 30)
//                }
//                .frame(maxWidth: .infinity)
//                .frame(height: 58)
//                .background(.customSecondary)
//                .cornerRadius(CornerRadius.large)
//                .padding(.bottom, Spacing.content)

                HStack {
                    UserInfoSectionTitle(title: "몸무게")

                    // TODO: 입력 제한 추가
                    TextField(
                        "",
                        text: Binding(
                            get: {
                                if let weight = weight {
                                    return String(format: "%.0f", weight)
                                } else {
                                    return ""
                                }
                            },
                            set: { newValue in
                                if let value = Double(newValue) {
                                    weight = value
                                } else {
                                    weight = nil
                                }
                            }
                        ),
                        prompt: Text("몸무게를 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    )
                    .keyboardType(.decimalPad)
                    .padding(.horizontal)
                    .padding(.leading, 14)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(.customSecondary)
                .cornerRadius(CornerRadius.large)
                .padding(.bottom, Spacing.content)
            }
            .padding(.horizontal)

            Spacer()

            FilledButton(title: "다음") {
                // TODO: 코어 데이터 추가 처리
                currentPage += 1
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    Preview()
}

private struct Preview: View {
    @State private var currentPage = 0

    var body: some View {
        UserInfoTabView(currentPage: $currentPage)
    }
}
