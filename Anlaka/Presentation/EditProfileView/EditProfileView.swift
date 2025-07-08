import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @StateObject private var container: EditProfileContainer
    @State private var selectedFiles: [SelectedFile] = []
    @State private var isShowingFilePicker = false
    @State private var isShowingDocumentPicker = false
    @State private var profileImageData: Data?
    @Binding var path: NavigationPath
    
    init(di: DIContainer, path: Binding<NavigationPath>) {
        self._container = StateObject(wrappedValue: di.makeEditProfieContainer())
        self._path = path
    }
    
    var body: some View {
        ZStack {
            Color.WarmLinen
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // CustomNavigationBar 추가
                CustomNavigationBar(title: "프로필 수정", leftButton: {
                    // 뒤로가기 버튼
                    Button(action: {
                        print("EditProfileView - 뒤로가기 버튼 클릭, 현재 path.count: \(path.count)")
                        path.removeLast()
                        print("EditProfileView - path.removeLast() 후 path.count: \(path.count)")
                    }) {
                        Image("chevron")
                            .font(.headline)
                            .foregroundColor(.MainTextColor)
                    }
                })
                
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
            }
        }
        .onAppear {
            container.handle(.initialRequest)
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
        .toastView(toast: $container.model.toast)
        .onChange(of: container.model.invalidFileIndices) { invalidIndices in
            // 유효하지 않은 파일이 새로 추가된 경우 토스트 표시
            if !invalidIndices.isEmpty {
                print("⚠️ EditProfileView: 유효하지 않은 파일 감지됨")
            }
        }
        .sheet(isPresented: $isShowingFilePicker) {
            FilePicker(selectedFiles: $selectedFiles, pickerType: .profile)
                .onChange(of: selectedFiles) { files in
                    container.handle(.validateFiles(files))
                }
        }
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPicker(selectedFiles: $selectedFiles, pickerType: .profile)
                .onChange(of: selectedFiles) { files in
                    container.handle(.validateFiles(files))
                }
        }
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            ProfileImageView(
                profileImageData: profileImageData,
                uploadedImagePath: container.model.profileImage?.profileImage,
                profileInfo: container.model.profile
            )
            
            // 파일 선택 버튼들
            HStack(spacing: 12) {
                // 갤러리에서 선택
                Button(action: {
                    isShowingFilePicker = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 14))
                        Text("갤러리")
                            .font(.pretendardCallout)
                    }
                    .foregroundColor(selectedFiles.isEmpty ? .OliveMist : .gray)
                }
                .disabled(!selectedFiles.isEmpty)
                
                // 문서에서 선택
                Button(action: {
                    isShowingDocumentPicker = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc")
                            .font(.system(size: 14))
                        Text("파일")
                            .font(.pretendardCallout)
                    }
                    .foregroundColor(selectedFiles.isEmpty ? .OliveMist : .gray)
                }
                .disabled(!selectedFiles.isEmpty)
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
            isEnabled: container.model.isNicknameValid && container.model.invalidFileIndices.isEmpty,
            onSave: saveProfile
        )
    }
    

    
    private func saveProfile() {
        // EditProfileRequestEntity 생성 (이미지 데이터는 별도로 처리)
        let editProfile = EditProfileRequestEntity(
            nick: container.model.nick.isEmpty ? nil : container.model.nick,
            introduction: container.model.introduction.isEmpty ? nil : container.model.introduction,
            phoneNum: container.model.phoneNum.isEmpty ? nil : container.model.phoneNum,
            profileImage: nil  // 이미지는 별도 API로 업로드
        )
        
        // 컨테이너에 저장 요청 (selectedFiles를 직접 전달)
        container.handle(.saveProfile(editProfile, selectedFiles))
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
            CustomAsyncImage.profile(imagePath: uploadedImagePath)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
        } else if let profileInfo = profileInfo,
                  let profileImage = profileInfo.profileImage,
                  !profileImage.isEmpty {
            // UserDefaults에 저장된 기존 이미지 (CustomAsyncImage로 표시)
            CustomAsyncImage.profile(imagePath: profileImage)
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
    
    // 글자수 계산을 위한 computed properties
    private var characterCount: Int {
        introduction.count
    }
    
    private var isOverLimit: Bool {
        characterCount > 60
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("자기소개")
                .font(.soyoHeadline)
                .foregroundColor(Color.MainTextColor)
            
            TextField("자기소개를 입력하세요", text: $introduction, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
                .onChange(of: introduction) { newValue in
                    // 글자수 제한 적용 (공백 포함 60자)
                    let charCount = newValue.count
                    
                    if charCount > 60 {
                        // 제한을 초과하면 이전 값으로 되돌리기
                        introduction = String(newValue.prefix(60))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isOverLimit ? Color.TomatoRed : Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            // 글자수 카운터
            HStack {
                Spacer()
                Text("\(characterCount)/60")
                    .font(.pretendardCaption)
                    .foregroundColor(isOverLimit ? Color.TomatoRed : Color.SubText)
            }
        }
    }
}

// MARK: - PhoneNumberInputField
struct PhoneNumberInputField: View {
    @Binding var phoneNum: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("전화번호")
                .font(.soyoHeadline)
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
                    .font(.soyoHeadline)
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
