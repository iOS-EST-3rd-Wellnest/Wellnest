//
//  ProfileDetailView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct ProfileDetailView: View {
    @ObservedObject var viewModel: UserInfoViewModel
    @ObservedObject var userEntity: UserEntity

    @Binding var currentPage: Int

    enum Field {
        case nickname
        case height
        case weight
    }

    @FocusState private var isFieldFocused: Field?
    @Binding var isNicknameValid: Bool

    @State private var tempImage: UIImage? = nil
    @State private var isImagePickerPresented: Bool = false
    @State private var nickname: String = ""
    @State private var selectedAge = ""
    @State private var selectedGender = ""
    @State private var height: Int?
    @State private var weight: Int?
    @State private var heightText: String = ""
    @State private var weightText: String = ""

    var isButtonDisabled: Bool {
        nickname.isEmpty || selectedAge.isEmpty || selectedGender.isEmpty || !isNicknameValid
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            /// 사용자 프로필 사진
            HStack {
                Spacer()
                ZStack {
                    if let image = tempImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                    } else {
                        Image("img_profile")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                    }
                }
                .onTapGesture {
                    isImagePickerPresented = true
                }

                Spacer()
            }
            .padding()
            .padding(.bottom, Spacing.content)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $tempImage)
            }
            .onAppear {
                if tempImage == nil,
                   let data = userEntity.profileImage,
                   let savedImage = UIImage(data: data) {
                    tempImage = savedImage
                }
            }

            /// 사용자 정보 입력 폼
            VStack {
                HStack {
                    Text("닉네임은 한글, 영문, 숫자만 입력 가능 (ex. a, ㅏ, ㅈ 불가능)")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .padding(.leading, 4)
                        .opacity(isNicknameValid ? 0 : 1)
                        .animation(.easeInOut, value: isNicknameValid)

                    Spacer()
                }

                /// 닉네임
                UserInfoForm(title: "닉네임", isRequired: true, isFocused: isFieldFocused == .nickname, isNicknameValid: $isNicknameValid) {
                    TextField(
                        "",
                        text: $nickname,
                        prompt: Text("10글자 이하로 입력해주세요")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.4))
                    )
                    .padding(.horizontal)
                    .padding(.leading, 10)
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
                UserInfoForm(title: "키", isFocused: isFieldFocused == .height) {
                    TextField(
                        "",
                        text: $heightText,
                        prompt: Text("cm 단위로 정수만 입력해주세요")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.4))
                    )
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                    .padding(.leading, 46)
                    .focused($isFieldFocused, equals: .height)
                    .onChange(of: heightText) { newValue in
                        heightText = newValue.onlyNumbers(maxLength: 3)
                        height = Int(heightText)
                    }
                }

                /// 몸무게
                UserInfoForm(title: "몸무게", isFocused: isFieldFocused == .weight) {
                    TextField(
                        "",
                        text: $weightText,
                        prompt: Text("kg 단위로 정수만 입력해주세요")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.4))
                    )
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                    .padding(.leading, 18)
                    .focused($isFieldFocused, equals: .weight)
                    .onChange(of: weightText) { newValue in
                        weightText = newValue.onlyNumbers(maxLength: 3)
                        weight = Int(weightText)
                    }
                }
            }
            .padding(.horizontal, Spacing.layout)
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
            /// 저장 버튼
            OnboardingButton(
                title: isFieldFocused == .height ? "다음" : "저장",
                isDisabled: isButtonDisabled,
                action: {
                    if isFieldFocused == .height {
                        /// 키 입력 후 → 몸무게로 포커스 이동
                        isFieldFocused = .weight
                    } else if isFieldFocused == .weight {
                        /// 몸무게 입력 후 → 저장하고 다음 페이지
                        saveUserInfo()
                        withAnimation { currentPage += 1 }
                    } else {
                        /// 혹시 포커스 없는 상태 → 저장하고 다음 페이지
                        saveUserInfo()
                        withAnimation { currentPage += 1 }
                    }
                },
                currentPage: $currentPage
            )
        }
        .onAppear {
            loadUserEntity()
        }
        .layoutWidth()
        .navigationTitle("사용자 정보")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation { dismiss() }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.wellnestOrange)
                        .font(.body)
                        .fontWeight(.regular)
                }
            }
        }
    }
}

/// 사용자 정보 CoreData 저장 및 로드
extension ProfileDetailView {
    /// CoreData 저장
    private func saveUserInfo() {
        if userEntity.id == nil {
            userEntity.id = UUID()
        }
        if userEntity.createdAt == nil {
            userEntity.createdAt = Date()
        }

        if let image = tempImage,
           let data = image.jpegData(compressionQuality: 0.8) {
            userEntity.profileImage = data
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
        if let data = userEntity.profileImage,
           let image = UIImage(data: data) {
            tempImage = image
        }
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
    @State private var title = ""
    @State private var isNicknameValid = true

    var body: some View {
        if let userEntity = userInfoVM.userEntity {
            ProfileDetailView(
                viewModel: userInfoVM,
                userEntity: userEntity,
                currentPage: $currentPage,
                isNicknameValid: $isNicknameValid
            )
        } else {
            ProgressView("Loading...")
        }
    }
}
