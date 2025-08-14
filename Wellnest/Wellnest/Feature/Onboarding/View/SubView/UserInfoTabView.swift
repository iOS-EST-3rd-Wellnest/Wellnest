//
//  UserInfoTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct UserInfoTabView: View {
    var userEntity: UserEntity

    @Binding var currentPage: Int
    @Binding var title: String

    @State private var nickname: String = ""
    @FocusState private var isNicknameFieldFocused: Bool

    @State private var selectedAge = ""
    @State private var selectedGender = ""
    @State private var height: Int?
    @State private var weight: Int?

    @State private var heightText: String = ""
    @State private var shakeTrigger: CGFloat = 0
    @State private var isInvalid: Bool = false

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
                            .foregroundColor(.secondary.opacity(0.4)) // TODO: 임시
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
                        ForEach(UserInfoOptions.ageRanges) { age in
                            Button {
                                selectedAge = age.value
                            } label: {
                                Text(age.title)
                            }
                        }
                    } label: {
                        AgeMenuLabel(selectedAge: selectedAge)
                    }
                    .padding(.horizontal)
                    .padding(.leading, 10)
                }

                /// 성별
                UserInfoForm(title: "성별", isRequired: true) {
                    HStack(spacing: 10) {
                        ForEach(UserInfoOptions.genders) { gender in
                            Button {
                                selectedGender = gender.value
                            } label: {
                                GenderMenuLabel(selectedGender: selectedGender, gender: gender)
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
                            get: { heightText },
                            set: { newValue in
                                // 숫자만 허용, 최대 3자리
                                let filtered = newValue.onlyNumbers(maxLength: 3)
                                if filtered != newValue {
                                    // 숫자가 아닌 값이 들어오면 흔들림 트리거
                                    withAnimation(.default) { shakeTrigger += 1 }
                                    isInvalid = true
                                } else {
                                    isInvalid = false
                                }

                                heightText = filtered
                                height = Int(filtered)
                            }
                        ),
                        prompt: Text("cm 단위로 정수만 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.5))
                    )
                    .keyboardType(.numberPad)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.leading, 46)
                    .modifier(ShakeEffect(animatableData: shakeTrigger))
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

struct AgeMenuLabel: View {
    let selectedAge: String

    var body: some View {
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
}

struct GenderMenuLabel: View {
    let selectedGender: String
    let gender: UserInfo

    var body: some View {
        Text(gender.title)
            .font(.body)
            .frame(width: 80, height: 30)
            .multilineTextAlignment(.center)
            .background(
                Capsule()
                    .fill(selectedGender == gender.value ? .blue : Color.gray.opacity(0.2))
            )
            .foregroundColor(selectedGender == gender.value ? .white : .black)
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10 // 흔드는 정도(거리)
    var shakesPerUnit = 3 // 흔드는 횟수
    var animatableData: CGFloat // 애니메이션 진행 정도(0 > 1)

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0
        ))
    }
}

extension UserInfoTabView {
    private func saveUserInfo() {
        // 이미 기존에 저장된 userEntity라면 id와 createdAt은 처음 한 번만 설정
        if userEntity.id == nil {
            userEntity.id = UUID()
        }
        if userEntity.createdAt == nil {
            userEntity.createdAt = Date()
        }

        userEntity.nickname = nickname
        userEntity.ageRange = selectedAge
        userEntity.gender = selectedGender

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
            selectedGender = gender
        }
        if let heightValue = userEntity.height?.intValue, heightValue != 0 {
            height = heightValue
        } else {
            height = nil
        }

        if let weightValue = userEntity.weight?.intValue, weightValue != 0 {
            weight = weightValue
        } else {
            weight = nil
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
                currentPage: $currentPage,
                title: $title
            )
        } else {
            ProgressView("Loading...")
        }
    }
}
