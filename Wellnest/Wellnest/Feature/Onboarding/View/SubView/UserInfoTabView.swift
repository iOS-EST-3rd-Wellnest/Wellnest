//
//  UserInfoTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct UserInfoTabView: View {
    var userEntity: UserEntity
    var viewModel: UserInfoViewModel

    @Binding var currentPage: Int
    @Binding var title: String

    @State private var nickname: String = ""
    @FocusState private var isNicknameFieldFocused: Bool

    @State private var selectedAge = ""
    let ageOptions = ["10대", "20대", "30대", "40대", "50대", "60대 이상"]

    @State private var selectedGender = ""
    let genderOptions = ["여성 👩🏻", "남성 👨🏻"]

    @State private var height: Int?
    @State private var weight: Int?

    let spacing = OnboardingCardLayout.spacing

    var isButtonDisabled: Bool {
        nickname.isEmpty || selectedAge.isEmpty || selectedGender.isEmpty
    }

    var body: some View {
        ScrollView {
            OnboardingTitleDescription(description: "당신의 정보를 알려주시면 그에 맞게 루틴을 추천해줄게요.")

            VStack {
                /// 닉네임
                UserInfoForm(title: "닉네임", isRequired: true) {
                    TextField(
                        "",
                        text: $nickname,
                        prompt: Text("10글자 이하로 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.secondary.opacity(0.4)) // TODO: 임시 컬러
                    )
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.leading, 10)
                    .focused($isNicknameFieldFocused)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onChange(of: nickname) { newValue in
                        nickname = newValue.onlyLettersAndNumbers(maxLength: 10)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isNicknameFieldFocused = true
                        }
                    }
                }

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
                                .foregroundColor(selectedAge.isEmpty ? .gray.opacity(0.5) : .black)
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

                /// 성별
                UserInfoForm(title: "성별", isRequired: true) {
//                    Picker("", selection: $selectedGender) {
//                        ForEach(genderOptions, id: \.self) {
//                            Text($0)
//                        }
//                    }
//                    .pickerStyle(.segmented)
//                    .padding()
//                    .padding(.leading, 16)

                    HStack(spacing: 10) {
                        ForEach(genderOptions, id: \.self) { option in
                            Button {
                                selectedGender = option
                            } label: {
                                Text(option)
                                    .font(.body)
                                    .frame(width: 80, height: 30)
                                    .multilineTextAlignment(.center)
                                    .background(
                                        Capsule()
                                            .fill(selectedGender == option ? .blue : Color.gray.opacity(0.2))
                                    )
                                    .foregroundColor(selectedGender == option ? .white : .black)
                            }
                        }
                    }
                    .padding(.leading, 36)

                    Spacer()
                }

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
                            .foregroundColor(.gray.opacity(0.5))
                    )
                    .keyboardType(.numberPad)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.leading, 46)
                }

                /// 몸무게
                UserInfoForm(title: "몸무게") {
                    TextField(
                        "",
                        text: Binding(
                            get: { weight.map(String.init) ?? "" },
                            set: { weight = Int($0.onlyNumbers(maxLength: 3)) }
                        ),
                        prompt: Text("kg 단위로 정수만 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.5))
                    )
                    .keyboardType(.numberPad)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.leading, 18)
                }
            }
            .padding(.horizontal, spacing)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            OnboardingButton(title: "다음", isDisabled: isButtonDisabled) {
                saveUserInfo()
                withAnimation { currentPage += 1 }
            }
        }
        .onAppear {
            title = "사용자 정보"
            loadUserEntity()
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

extension UserInfoTabView {
    private func saveUserInfo() {
        let selectedGenterText = selectedGender
                .components(separatedBy: " ")
                .first ?? selectedGender

        // 이미 기존에 저장된 userEntity라면 id와 createdAt은 처음 한 번만 설정
        if userEntity.id == nil {
            userEntity.id = UUID()
        }
        if userEntity.createdAt == nil {
            userEntity.createdAt = Date()
        }
        userEntity.nickname = nickname
        userEntity.ageRange = selectedAge
        userEntity.gender = selectedGenterText
        if let height = height, let weight = weight {
            userEntity.height = NSNumber(value: height)
            userEntity.weight = NSNumber(value: weight)
        } else {
            userEntity.height = nil
            userEntity.weight = nil
        }

        print(userEntity)
        try? CoreDataService.shared.saveContext()
    }

    private func loadUserEntity() {
        if let nicknameValue = userEntity.nickname {
            nickname = nicknameValue
        }
        if let age = userEntity.ageRange {
            selectedAge = age
        }
        if let gender = userEntity.gender {
            if gender == "여성" {
                selectedGender = "여성 👩🏻"
            } else if gender == "남성" {
                selectedGender = "남성 👨🏻"
            }
        }
        if let height = height {
            userEntity.height = NSNumber(value: height)
        } else {
            userEntity.height = nil
        }

        if let weight = weight {
            userEntity.weight = NSNumber(value: weight)
        } else {
            userEntity.weight = nil
        }
    }
}

#Preview {
    Preview()
}

private struct Preview: View {
    @StateObject private var userInfoVM = UserInfoViewModel()
    @State private var currentPage = 0
    @State private var title = "사용자 정보"

    var body: some View {
        if let userEntity = userInfoVM.userEntity {
            UserInfoTabView(
                userEntity: userEntity,
                viewModel: userInfoVM,
                currentPage: $currentPage,
                title: $title
            )
        } else {
            ProgressView("Loading...")
        }
    }
}
