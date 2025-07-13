import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @StateObject private var container: EditProfileContainer
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImageData: Data?
    @Binding var path: NavigationPath
    
    init(di: DIContainer, path: Binding<NavigationPath>) {
        self._container = StateObject(wrappedValue: EditProfileContainer(repository: di.networkRepository))
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
        .navigationTitle("프로필 수정")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    path.removeLast()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.MainTextColor)
                        .font(.system(size: 18, weight: .medium))
                }
            }
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
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            // 프로필 이미지 표시
            if let profileImageData = profileImageData,
               let uiImage = UIImage(data: profileImageData) {
                // 사용자가 갤러리에서 선택한 이미지 (UIImage로 표시)
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
            } else if let uploadedImagePath = container.model.profileImage?.profileImage,
                      !uploadedImagePath.isEmpty {
                // 업로드 완료된 이미지 (CustomAsyncImage로 표시)
                CustomAsyncImage(imagePath: uploadedImagePath)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
            } else if let profileInfo = container.model.profile,
                      let profileImage = profileInfo.profileImage,
                      !profileImage.isEmpty {
                // UserDefaults에 저장된 기존 이미지 (CustomAsyncImage로 표시)
                CustomAsyncImage(imagePath: profileImage)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
            } else {
                // 기본 프로필 이미지
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 40))
                    )
            }
            
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
            VStack(alignment: .leading, spacing: 8) {
                Text("닉네임")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.MainTextColor)
                
                TextField("닉네임을 입력하세요", text: $container.model.nick)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
            }
            
            // 자기소개 입력 필드
            VStack(alignment: .leading, spacing: 8) {
                Text("자기소개")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.MainTextColor)
                
                TextField("자기소개를 입력하세요", text: $container.model.introduction, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            // 전화번호 입력 필드
            VStack(alignment: .leading, spacing: 8) {
                Text("전화번호")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.MainTextColor)
                
                TextField("전화번호를 입력하세요", text: $container.model.phoneNum)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
            }
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveProfile) {
            HStack {
                if container.model.isLoading {
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
                    .fill(Color.OliveMist)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(container.model.isLoading)
        .padding(.top, 20)
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
