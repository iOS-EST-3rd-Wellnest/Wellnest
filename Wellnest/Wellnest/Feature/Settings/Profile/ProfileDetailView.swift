//
//  ProfileDetailView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI
import UIKit

struct ProfileDetailView: View {
    @ObservedObject var viewModel: UserInfoViewModel
    var userEntity: UserEntity

    enum Field {
        case nickname
        case height
        case weight
    }

    @FocusState private var isFieldFocused: Field?

    @State private var nickname: String = ""
    @State private var selectedAge = ""
    @State private var selectedGender = ""
    @State private var height: Int?
    @State private var weight: Int?
    @State private var heightText: String = ""
    @State private var weightText: String = ""

    var isButtonDisabled: Bool {
        nickname.isEmpty || selectedAge.isEmpty || selectedGender.isEmpty
    }

//    @Binding var name: String
//    @Binding var height: String
//    @Binding var weight: String
//    @State private var selectedAge: UserAgeRange? = nil // 임시
////    @State private var selectedGender: UserGender? = nil // 임시
//    @State private var selectedGender: String = "여자"
//    var genderOptions = ["여자", "남자"]
    
    @State private var tempImage: UIImage? = nil
    @State private var isImagePickerPresented: Bool = false
    
//    @Binding var profileImage: UIImage?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
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
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 150, height: 150)
                            .overlay {
                                Text("프로필 사진 수정")
                                    .foregroundStyle(.white)
                            }
                    }
                }
                .onTapGesture {
                    isImagePickerPresented = true
                }

                Spacer()
            }
            .padding()
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
                /// 닉네임
                UserInfoForm(title: "닉네임", isRequired: true) {
                    TextField(
                        "",
                        text: $nickname,
                        prompt: Text("10글자 이하로 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.4)) // TODO: 임시
                    )
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.leading, 10)
                    .focused($isFieldFocused, equals: .nickname)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.done)
                    .onChange(of: nickname) { newValue in
                        nickname = newValue.onlyLettersAndNumbers(maxLength: 10)
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
                UserInfoForm(title: "키") {
                    TextField(
                        "",
                        text: $heightText,
                        prompt: Text("cm 단위로 정수만 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.4))
                    )
                    .keyboardType(.numberPad)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.leading, 46)
                    .focused($isFieldFocused, equals: .height)
                    .onChange(of: heightText) { newValue in
                        heightText = newValue.onlyNumbers(maxLength: 3)
                        height = Int(heightText)
                    }
                }

                /// 몸무게
                UserInfoForm(title: "몸무게") {
                    TextField(
                        "",
                        text: $weightText,
                        prompt: Text("kg 단위로 정수만 입력해주세요.")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.4))
                    )
                    .keyboardType(.numberPad)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.leading, 18)
                    .focused($isFieldFocused, equals: .weight)
                    .onChange(of: weightText) { newValue in
                        weightText = newValue.onlyNumbers(maxLength: 3)
                        weight = Int(weightText)
                    }
                }
            }
            .padding(.horizontal, OnboardingCardLayout.spacing)
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
            .onAppear {
                loadUserEntity()
            }

            Spacer()

            /// 저장 버튼
            FilledButton(title: "저장") {
                saveUserInfo()
                withAnimation { dismiss() }
            }
            .padding(.horizontal, OnboardingCardLayout.spacing)
            .padding(.bottom, Spacing.content)

            //                Section {
            //                    HStack {
            //                        Text("이름")
            //                            .foregroundStyle(.secondary)
            //                            .padding(.trailing)
            //
            //                        TextField("이름을 입력해주세요.", text: $name)
            //                    }
            //
            //                    HStack {
            //                        Text("나이")
            //                            .foregroundStyle(.secondary)
            //                            .padding(.trailing)
            //
            //                        Menu {
            //                            ForEach(UserAgeRange.allCases) { group in
            //                                Button(group.rawValue) {
            //                                    selectedAge = group
            //                                }
            //                            }
            //                        } label: {
            //                            HStack {
            //                                Text(selectedAge?.rawValue ?? "나이를 선택해주세요.")
            //                                    .foregroundStyle(selectedAge == nil ? .gray.opacity(0.5) : .primary)
            //
            //                                Spacer()
            //
            //                                Image(systemName: "chevron.down")
            //                                    .foregroundStyle(selectedAge == nil ? .gray.opacity(0.5) : .primary)
            //
            //                            }
            //                        }
            //                    }
            //
            //                    HStack {
            //                        Text("성별")
            //                            .padding(.trailing)
            //                            .foregroundStyle(.secondary)
            //
            //                        Picker("", selection: $selectedGender) {
            //                            ForEach(genderOptions, id: \.self) {
            //                                Text($0)
            //                            }
            //                        }
            //                        .pickerStyle(.segmented)
            //                        .padding(.leading, 20)
            //
            //                        //                        Menu {
            //                        //                            ForEach(UserGender.allCases) { group in
            //                        //                                Button(group.rawValue) {
            //                        //                                    selectedGender = group
            //                        //                                }
            //                        //                            }
            //                        //                        } label: {
            //                        //                            Text(selectedGender?.rawValue ?? "성별을 선택해주세요.")
            //                        //                                .foregroundStyle(selectedGender == nil ? .gray.opacity(0.5) : .primary)
            //                        //
            //                        //                            Spacer()
            //                        //
            //                        //                            Image(systemName: "chevron.down")
            //                        //                                .foregroundStyle(selectedGender == nil ? .gray.opacity(0.5) : .primary)
            //                        //                        }
            //                    }
            //
            //                    HStack {
            //                        Text("키 / 몸무게")
            //                            .foregroundStyle(.secondary)
            //                            .padding(.trailing)
            //
            //                        Spacer()
            //
            //                        HStack {
            //                            TextField("키", text: $height)
            //                                .keyboardType(.numberPad)
            //                                .frame(width: 50)
            //
            //                            Text("cm")
            //                                .foregroundStyle(.secondary)
            //                        }
            //                        .frame(maxWidth: .infinity, alignment: .leading)
            //
            //                        HStack {
            //                            TextField("몸무게", text: $weight)
            //                                .keyboardType(.numberPad)
            //                                .frame(width: 50)
            //
            //                            Text("kg")
            //                                .foregroundStyle(.secondary)
            //                        }
            //                        .frame(maxWidth: .infinity, alignment: .trailing)
            //                    }
            //                }
            //                .navigationTitle("프로필 수정")
            //                .navigationBarTitleDisplayMode(.inline)

        }
        .navigationTitle("사용자 정보")
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button {
//                    withAnimation { dismiss() }
//                } label: {
//                    Image(systemName: "xmark")
//                        .foregroundColor(.gray) // TODO: 다른 네비게이션 바와 색 맞추기
//                }
//            }
//        }
    }
}

extension ProfileDetailView {
    /// CoreData에 저장
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

        print(userEntity)
        try? CoreDataService.shared.saveContext()
    }

    /// CoreData에서 불러옴
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

    var body: some View {
        if let userEntity = userInfoVM.userEntity {
            ProfileDetailView(
                viewModel: userInfoVM,
                userEntity: userEntity
            )
        } else {
            ProgressView("Loading...")
        }
    }
}
