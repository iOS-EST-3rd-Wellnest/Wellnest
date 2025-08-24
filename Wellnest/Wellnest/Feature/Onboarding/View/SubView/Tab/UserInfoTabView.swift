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

    enum Field {
        case nickname
        case ageRange
        case gender
        case height
        case weight
    }

    @FocusState private var isFieldFocused: Field?
    @State private var selectedField: Field?
    @Binding var isNicknameValid: Bool

    @State private var nickname: String = ""
    @State private var selectedAge = ""
    @State private var selectedGender = ""
    @State private var height: Int?
    @State private var weight: Int?
    @State private var heightText: String = ""
    @State private var weightText: String = ""

    let spacing = OnboardingCardLayout.spacing

    var isButtonDisabled: Bool {
        nickname.isEmpty || selectedAge.isEmpty || selectedGender.isEmpty || !isNicknameValid
    }

    var body: some View {
        ScrollView {
            OnboardingTitleDescription(description: "당신의 정보를 알려주시면 그에 맞게 루틴을 추천해줄게요.")

            VStack {
                /// 닉네임
                // TODO: 닉네임 정규식 안지켰을 때 흔들리거나 빨간색 표시하거나 글씨로 알려주기
                UserInfoForm(title: "닉네임", isRequired: true, isFocused: isFieldFocused == .nickname, isNicknameValid: $isNicknameValid) {
                    TextField(
                        "",
                        text: $nickname,
                        prompt: Text("10글자 이하로 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.4))
                    )
                    .foregroundColor(isNicknameValid ? .black : .red)
                    .padding(.horizontal)
                    .padding(.leading, 20)
                    .focused($isFieldFocused, equals: .nickname)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.done)
                    .onChange(of: nickname) { newValue in
                        nickname = newValue.onlyLettersAndNumbers(maxLength: 10)
                        isNicknameValid = NicknameValidator.isNicknameValid(nickname)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isFieldFocused = .nickname
                        }
                    }
                    .onSubmit {
                        isFieldFocused = nil
                    }
                }

                /// 연령대
                // TODO: 연령대, 성별 포커스 다시 하기, 설정뷰도 동일하게 수정
                UserInfoForm(title: "연령대", isRequired: true, isFocused: selectedField == .ageRange) {
                    Menu {
                        ForEach(UserInfoOptions.ageRanges) { age in
                            Button {
                                selectedAge = age.value
                                selectedField = .ageRange
                            } label: {
                                Text(age.title)
                            }
                        }
                    } label: {
                        AgeMenuLabel(selectedAge: selectedAge)
                    }
                    .padding(.horizontal)
                    .padding(.leading, 20)
                }

                /// 성별
                UserInfoForm(title: "성별", isRequired: true, isFocused: selectedField == .gender) {
                    HStack(spacing: 10) {
                        ForEach(UserInfoOptions.genders) { gender in
                            Button {
                                selectedGender = gender.value
                                selectedField = .gender
                            } label: {
                                GenderMenuLabel(selectedGender: selectedGender, gender: gender)
                            }
                        }
                    }
                    .padding(.leading, 48)

                    Spacer()
                }

                /// 키
                UserInfoForm(title: "키(cm)", isFocused: isFieldFocused == .height) {
                    TextField(
                        "",
                        text: $heightText,
                        prompt: Text("소수점은 제외하고 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.4))
                    )
                    .keyboardType(.numberPad)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.leading, 22)
                    .focused($isFieldFocused, equals: .height)
                    .onChange(of: heightText) { newValue in
                        heightText = newValue.onlyNumbers(maxLength: 3)
                        height = Int(heightText)
                    }
                }

                /// 몸무게
                UserInfoForm(title: "몸무게(kg)", isFocused: isFieldFocused == .weight) {
                    TextField(
                        "",
                        text: $weightText,
                        prompt: Text("소수점은 제외하고 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.4))
                    )
                    .keyboardType(.numberPad)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .focused($isFieldFocused, equals: .weight)
                    .onChange(of: weightText) { newValue in
                        weightText = newValue.onlyNumbers(maxLength: 3)
                        weight = Int(weightText)
                    }
                }
            }
            .padding(.horizontal, spacing)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    if isFieldFocused == .height {
                        Button("다음") { isFieldFocused = .weight }
                    } else if isFieldFocused == .weight {
                        Button("완료") { isFieldFocused = nil }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            OnboardingButton(
                title: "다음",
                isDisabled: isButtonDisabled,
                action: {
                    saveUserInfo()
                    withAnimation { currentPage += 1 }
                },
                currentPage: $currentPage
            )
        }
        .onAppear {
            title = "사용자 정보"
            loadUserEntity()
        }
    }
}

/// 입력폼 타이틀 레이아웃
struct UserInfoFormTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundColor(.primary) // label로 변경
            .padding(.vertical)
            .padding(.leading, 28)
    }
}

/// 입력폼 레이아웃
struct UserInfoForm<Content: View>: View {
    let title: String
    let isRequired: Bool
    let isFocused: Bool
    @Binding var isNicknameValid: Bool
    @ViewBuilder let content: Content

    init(title: String, isRequired: Bool = false, isFocused: Bool = false, isNicknameValid: Binding<Bool> = .constant(true), @ViewBuilder content: () -> Content) {
        self.title = title
        self.isRequired = isRequired
        self.isFocused = isFocused
        self._isNicknameValid = isNicknameValid
        self.content = content()
    }

    var body: some View {
        HStack {
            UserInfoFormTitle(title: title + (isRequired ? " *" : ""))
            content
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(Color(.systemGray6))
        .cornerRadius(CornerRadius.large)
        .overlay{
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .strokeBorder(borderColor, lineWidth: 0.5)
        }
        .padding(.bottom, Spacing.content)
    }

    private var borderColor: Color {
        if isFocused {
            if title.contains("닉네임") {
                return isNicknameValid ? .secondary.opacity(0.6) : .red
            } else {
                return .secondary.opacity(0.6)
            }
        } else {
            return .clear
        }
    }
}

/// 닉네임 유효성 검사
struct NicknameValidator {
    static func isNicknameValid(_ text: String) -> Bool {
        let pattern = "^[가-힣a-zA-Z0-9]*$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}

/// 나이 선택 버튼 레이아웃
struct AgeMenuLabel: View {
    let selectedAge: String

    var body: some View {
        HStack {
            Text(selectedAge.isEmpty ? "연령대를 선택해주세요." : selectedAge)
                .foregroundColor(selectedAge.isEmpty ? .gray.opacity(0.5) : .black)
                .font(selectedAge.isEmpty ? .footnote : .body)

            Spacer()

            Image(systemName: "chevron.down")
                .foregroundColor(.primary)
                .imageScale(.small)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 성별 선택 버튼 레이아웃
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
                    .fill(selectedGender == gender.value ? .wellnestOrange : Color.gray.opacity(0.2))
            )
            .foregroundColor(selectedGender == gender.value ? .white : .black)
    }
}

/// 사용자 정보 CoreData 저장 및 로드
extension UserInfoTabView {
    /// CoreData 저장
    private func saveUserInfo() {
        /// 이미 기존에 저장된 userEntity라면 id와 createdAt은 처음 한 번만 설정
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

        try? CoreDataService.shared.saveContext()
    }

    /// CoreData 로드
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
            heightText = "\(heightValue)"
        } else {
            height = nil
        }
        if let weightValue = userEntity.weight?.intValue, weightValue != 0 {
            weight = weightValue
            weightText = "\(weightValue)"
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
    @State private var isNicknameValid = true

    var body: some View {
        if let userEntity = userInfoVM.userEntity {
            UserInfoTabView(
                userEntity: userEntity,
                currentPage: $currentPage,
                title: $title,
                isNicknameValid: $isNicknameValid
            )
        } else {
            ProgressView("Loading...")
        }
    }
}
