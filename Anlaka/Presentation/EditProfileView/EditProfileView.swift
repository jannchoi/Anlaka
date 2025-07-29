import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @StateObject private var container: EditProfileContainer
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImageData: Data?
    @Binding var path: NavigationPath
    
    init(di: DIContainer, path: Binding<NavigationPath>) {
        self._container = StateObject(wrappedValue: di.makeEditProfieContainer())
        self._path = path
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 프로필 이미지 섹션
                profileImageSection
                
                // 입력 필드들
                inputFieldsSection
                
                // 저장 버튼
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            EditProfileToolbar(path: $path)
        }
        .onAppear {
            container.handle(.initialRequest)
        }
        .onChange(of: selectedImage) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    profileImageData = data
                }
            }
        }
        .alert("오류", isPresented: .constant(container.model.errorMessage != nil)) {
            Button("확인") {
                container.model.errorMessage = nil
            }
        } message: {
            if let errorMessage = container.model.errorMessage {
                Text(errorMessage)
            }
        }
        .overlay(
            SuccessToastOverlay(showSuccessToast: container.model.showSuccessToast)
        )
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            ProfileImageView(
                profileImageData: profileImageData,
                uploadedImagePath: container.model.profileImage?.profileImage,
                profileInfo: container.model.profile
            )
            
            // 이미지 선택 버튼
            PhotosPicker(selection: $selectedImage, matching: .images) {
                Text("프로필 이미지 변경")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Input Fields Section
    private var inputFieldsSection: some View {
        VStack(spacing: 20) {
            // 닉네임 입력 필드
            NicknameInputField(container: container)
            
            // 자기소개 입력 필드
            IntroductionInputField(introduction: $container.model.introduction)
            
            // 전화번호 입력 필드
            PhoneNumberInputField(phoneNum: $container.model.phoneNum)
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        SaveProfileButton(
            isLoading: container.model.isLoading,
            isEnabled: container.model.isNicknameValid,
            onSave: saveProfile
        )
    }
    
    // MARK: - Helper Methods
    private func saveProfile() {
        // EditProfileRequestEntity 생성 (이미지 데이터는 별도로 처리)
        let editProfile = EditProfileRequestEntity(
            nick: container.model.nick.isEmpty ? nil : container.model.nick,
            introduction: container.model.introduction.isEmpty ? nil : container.model.introduction,
            phoneNum: container.model.phoneNum.isEmpty ? nil : container.model.phoneNum,
            profileImage: nil  // 이미지는 별도 API로 업로드
        )
        
        // 컨테이너에 저장 요청
        container.handle(.saveProfile(editProfile, profileImageData))
    }
}

// MARK: - EditProfileToolbar
struct EditProfileToolbar: ToolbarContent {
    @Binding var path: NavigationPath
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            BackButton(path: $path)
        }
        
        ToolbarItem(placement: .principal) {
            NavigationTitle()
        }
    }
}

// MARK: - BackButton
struct BackButton: View {
    @Binding var path: NavigationPath
    
    var body: some View {
        Button(action: {
            path.removeLast()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(Color.MainTextColor)
                .font(.system(size: 18, weight: .medium))
        }
    }
}

// MARK: - NavigationTitle
struct NavigationTitle: View {
    var body: some View {
        Text("프로필 수정")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(Color.MainTextColor)
    }
}

// MARK: - ProfileImageView
struct ProfileImageView: View {
    let profileImageData: Data?
    let uploadedImagePath: String?
    let profileInfo: MyProfileInfoEntity?
    
    var body: some View {
        if let profileImageData = profileImageData,
           let uiImage = UIImage(data: profileImageData) {
            // 사용자가 갤러리에서 선택한 이미지 (UIImage로 표시)
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
        } else if let uploadedImagePath = uploadedImagePath,
                  !uploadedImagePath.isEmpty {
            // 업로드 완료된 이미지 (CustomAsyncImage로 표시)
            CustomAsyncImage(imagePath: uploadedImagePath)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
        } else if let profileInfo = profileInfo,
                  let profileImage = profileInfo.profileImage,
                  !profileImage.isEmpty {
            // UserDefaults에 저장된 기존 이미지 (CustomAsyncImage로 표시)
            CustomAsyncImage(imagePath: profileImage)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
        } else {
            // 기본 프로필 이미지
            DefaultProfileImageView()
        }
    }
}

// MARK: - DefaultProfileImageView
struct DefaultProfileImageView: View {
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 40))
            )
    }
}

// MARK: - NicknameInputField
struct NicknameInputField: View {
    @ObservedObject var container: EditProfileContainer
    
    var body: some View {
        CustomTextField(
            title: "닉네임",
            text: $container.model.nick,
            validationMessage: container.model.nicknameValidationMessage,
            isValid: container.model.isNicknameValid
        )
        .onChange(of: container.model.nick) {
            container.handle(.nicknameChanged($0))
        }
    }
}

// MARK: - IntroductionInputField
struct IntroductionInputField: View {
    @Binding var introduction: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("자기소개")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.MainTextColor)
            
            TextField("자기소개를 입력하세요", text: $introduction, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
}

// MARK: - PhoneNumberInputField
struct PhoneNumberInputField: View {
    @Binding var phoneNum: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("전화번호")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.MainTextColor)
            
            TextField("전화번호를 입력하세요", text: $phoneNum)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
        }
    }
}

// MARK: - SaveProfileButton
struct SaveProfileButton: View {
    let isLoading: Bool
    let isEnabled: Bool
    let onSave: () -> Void
    
    var body: some View {
        Button(action: onSave) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text("저장")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? Color.OliveMist : Color.Deselected)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled || isLoading)
        .padding(.top, 20)
    }
}

// MARK: - SuccessToastOverlay
struct SuccessToastOverlay: View {
    let showSuccessToast: Bool
    
    var body: some View {
        Group {
            if showSuccessToast {
                VStack {
                    Spacer()
                    SuccessToastMessage()
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showSuccessToast)
            }
        }
    }
}

// MARK: - SuccessToastMessage
struct SuccessToastMessage: View {
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.SteelBlue)
            Text("프로필이 성공적으로 저장되었습니다")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.Gray75.opacity(0.8))
        )
    }
}

// MARK: - PressableButtonStyle
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isPressed ? Color.Deselected : Color.OliveMist)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
