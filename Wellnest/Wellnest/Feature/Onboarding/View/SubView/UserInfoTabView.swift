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
    @FocusState private var isNicknameFieldFocused: Bool

    @State private var selectedAge = ""
    let ageOptions = ["10대", "20대", "30대", "40대", "50대", "60대 이상"]

    @State var selectedGender = ""
    var genderOptions = ["여자", "남자"]

    @State private var height: Int?
//    @State private var selectedHeight = ""
//    let heightOptions = ["140대 이하", "150대", "160대", "170대", "180대", "190대 이상"]

    @State private var weight: Int?
//    @State private var selectedWeight = ""
//    let weightOptions = ["20kg대 이하", "30kg대", "40kg대", "50kg대", "60kg대", "70kg대", "80kg대", "90kg대", "100kg대 이상"]

    let spacing = OnboardingCardLayout.spacing

    var isButtonDisabled: Bool {
        nickname.isEmpty || selectedAge.isEmpty || selectedGender.isEmpty
    }

    var body: some View {
        VStack {
            OnboardingTitle(title: "사용자 정보", description: "당신의 정보를 알려주시면 그에 맞게 루틴을 추천해줄게요.", currentPage: currentPage, onBack: { withAnimation { currentPage -= 1 } })

            VStack {
                HStack {
                    Text("* 필수항목")
                        .font(.caption2)

                    Spacer()
                }
                .padding(.horizontal, Spacing.content)
                .padding(.bottom, Spacing.content)

                /// 닉네임
                UserInfoForm(title: "닉네임", isRequired: true) {
                    TextField(
                        "",
                        text: $nickname,
                        prompt: Text("10글자 이하로 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    )
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.leading, 10)
                    .focused($isNicknameFieldFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: nickname) { newValue in
                        nickname = newValue.onlyLettersAndNumbers(maxLength: 10)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isNicknameFieldFocused = true
                        }
                    }
                }

//                HStack {
//                    UserInfoFormTitle(title: "닉네임 *")
//
//                    TextField(
//                        "",
//                        text: $nickname,
//                        prompt: Text("10글자 이하로 입력해주세요.")
//                            .font(.footnote)
//                            .foregroundColor(.gray)
//                    )
//                    .foregroundColor(.black)
//                    .padding(.horizontal)
//                    .padding(.leading, 10)
//                    .focused($isNicknameFieldFocused)
//                    .textInputAutocapitalization(.never)
//                    .autocorrectionDisabled()
//                    .onChange(of: nickname) { newValue in
//                        let filtered = newValue
//                            .filter { $0.isLetter || $0.isNumber }
//                            .prefix(10)
//
//                        if nickname != String(filtered) {
//                            nickname = String(filtered)
//                        }
//                    }
//                }
//                .frame(maxWidth: .infinity)
//                .frame(height: 58)
//                .background(.customSecondary)
//                .cornerRadius(CornerRadius.large)
//                .padding(.bottom, Spacing.content)
//                .onAppear {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        isNicknameFieldFocused = true
//                    }
//                }

                /// 연령대
                UserInfoForm(title: "연령대", isRequired: true) {
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
                                .foregroundColor(selectedAge.isEmpty ? .gray : .black)
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

//                HStack {
//                    UserInfoFormTitle(title: "연령대 *")
//
//                    Menu {
//                        ForEach(ageOptions, id: \.self) { age in
//                            Button(action: {
//                                selectedAge = age
//                            }) {
//                                Text(age)
//                            }
//                        }
//                    } label: {
//                        HStack {
//                            Text(selectedAge.isEmpty ? "연령대를 선택해주세요." : selectedAge)
//                                .foregroundColor(selectedAge.isEmpty ? .gray : .black)
//                                .font(selectedAge.isEmpty ? .footnote : .body)
//
//                            Spacer()
//
//                            // TODO: 메뉴 클릭 시 chevron.up으로 바뀌는 것도 좋을 것 같음
//                            Image(systemName: "chevron.down")
//                                .foregroundColor(.primary)
//                                .imageScale(.small)
//                        }
//                        .frame(maxWidth: .infinity)
//                    }
//                    .padding(.horizontal)
//                    .padding(.leading, 10)
//                }
//                .frame(maxWidth: .infinity)
//                .frame(height: 58)
//                .background(.customSecondary)
//                .cornerRadius(CornerRadius.large)
//                .padding(.bottom, Spacing.content)

                /// 성별
                UserInfoForm(title: "성별", isRequired: true) {
                    // TODO: picker 다크모드 대응
                    Picker("", selection: $selectedGender) {
                        ForEach(genderOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .padding(.leading, 20)
                }

//                HStack {
//                    UserInfoFormTitle(title: "성별 *")
//
//                    // TODO: picker 다크모드 대응
//                    Picker("", selection: $selectedGender) {
//                        ForEach(genderOptions, id: \.self) {
//                            Text($0)
//                        }
//                    }
//                    .pickerStyle(.segmented)
//                    .padding()
//                    .padding(.leading, 20)
//                }
//                .frame(maxWidth: .infinity)
//                .frame(height: 58)
//                .background(.customSecondary)
//                .cornerRadius(CornerRadius.large)
//                .padding(.bottom, Spacing.content)

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

                /// 키
                UserInfoForm(title: "키") {
                    TextField(
                        "",
                        text: Binding(
                            get: { height.map(String.init) ?? "" },
                            set: { height = Int($0.onlyNumbers(maxLength: 3)) }
                        ),
                        prompt: Text("cm 단위로 정수만 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    )
                    .keyboardType(.decimalPad)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.leading, 42)
                }

//                HStack {
//                    UserInfoFormTitle(title: "키")
//
//                    TextField(
//                        "",
//                        text: Binding(
//                            get: {
//                                if let height = height {
//                                    return String(height)
//                                } else {
//                                    return ""
//                                }
//                            },
//                            set: { newValue in
//                                let filtered = newValue.filter { $0.isNumber }
//                                let limited = String(filtered.prefix(3))
//
//                                if let value = Int(limited) {
//                                    height = value
//                                } else {
//                                    height = nil
//                                }
//                            }
//                        ),
//                        prompt: Text("cm 단위로 정수만 입력해주세요.")
//                            .font(.footnote)
//                            .foregroundColor(.gray)
//                    )
//                    .keyboardType(.decimalPad)
//                    .foregroundColor(.black)
//                    .padding(.horizontal)
//                    .padding(.leading, 42)
//
//                }
//                .frame(maxWidth: .infinity)
//                .frame(height: 58)
//                .background(.customSecondary)
//                .cornerRadius(CornerRadius.large)
//                .padding(.bottom, Spacing.content)

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

                /// 몸무게
                UserInfoForm(title: "몸무게") {
                    TextField(
                        "",
                        text: Binding(
                            get: { height.map(String.init) ?? "" },
                            set: { height = Int($0.onlyNumbers(maxLength: 3)) }
                        ),
                        prompt: Text("kg 단위로 정수만 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    )
                    .keyboardType(.decimalPad)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.leading, 14)
                }

//                HStack {
//                    UserInfoFormTitle(title: "몸무게")
//
//                    TextField(
//                        "",
//                        text: Binding(
//                            get: {
//                                if let weight = weight {
//                                    return String(weight)
//                                } else {
//                                    return ""
//                                }
//                            },
//                            set: { newValue in
//                                let filtered = newValue.filter { $0.isNumber }
//                                let limited = String(filtered.prefix(3))
//
//                                if let value = Int(limited) {
//                                    weight = value
//                                } else {
//                                    weight = nil
//                                }
//                            }
//                        ),
//                        prompt: Text("kg 단위로 정수만 입력해주세요.")
//                            .font(.footnote)
//                            .foregroundColor(.gray)
//                    )
//                    .keyboardType(.decimalPad)
//                    .foregroundColor(.black)
//                    .padding(.horizontal)
//                    .padding(.leading, 14)
//                }
//                .frame(maxWidth: .infinity)
//                .frame(height: 58)
//                .background(.customSecondary)
//                .cornerRadius(CornerRadius.large)
//                .padding(.bottom, Spacing.content)
            }
            .padding(.horizontal, spacing)

            Spacer()

            FilledButton(title: "다음") {
                withAnimation {
                    currentPage += 1
                }
            }
            .disabled(isButtonDisabled)
            .opacity(isButtonDisabled ? 0.5 : 1.0)
            .padding()
        }
        .onTapGesture {
            UIApplication.hideKeyboard()
        }
    }
}

struct UserInfoFormTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundColor(.black)
            .padding(.vertical)
            .padding(.leading, 28)
    }
}

struct UserInfoForm<Content: View>: View {
    let title: String
    let isRequired: Bool
    @ViewBuilder let content: Content

    init(title: String, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isRequired = isRequired
        self.content = content()
    }

    var body: some View {
        HStack {
            UserInfoFormTitle(title: title + (isRequired ? " *" : ""))
            content
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(.customSecondary)
        .cornerRadius(CornerRadius.large)
        .padding(.bottom, Spacing.content)
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
