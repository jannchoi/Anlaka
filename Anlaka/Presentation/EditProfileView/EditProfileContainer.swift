import Foundation

struct EditProfileModel {
    var errorMessage: String? = nil
    var profileImage: ProfileImageEntity? = nil
    var profile: MyProfileInfoEntity? = nil
    var isLoading: Bool = false
    
    // View에서 사용할 필드 데이터
    var nick: String = ""
    var introduction: String = ""
    var phoneNum: String = ""
    
    // 닉네임 유효성 검사
    var isNicknameValid: Bool = true
    var nicknameValidationMessage: String = ""
    
    // 파일 검증 관련 상태
    var invalidFileIndices: Set<Int> = []
    var invalidFileReasons: [Int: String] = [:]
    
    // CustomToastView 관련 상태
    var toast: FancyToast? = nil
}

enum EditProfileIntent {
    case initialRequest
    case nicknameChanged(String)
    case validateFiles([SelectedFile])
    case saveProfile(EditProfileRequestEntity, [SelectedFile])
}

@MainActor
final class EditProfileContainer: ObservableObject {
    @Published var model =  EditProfileModel()
    private let repository: NetworkRepository
    init(repository: NetworkRepository) {
        self.repository = repository
    }
    
    func handle(_ intent: EditProfileIntent) {
        switch intent {
        case .initialRequest:
            
            getMyProfileInfo()
            
        case .nicknameChanged(let newNick):
            model.nick = newNick
            validateNickname(newNick)
        case .validateFiles(let files):
            validateFiles(files)
        case .saveProfile(let editProfile, let selectedFiles):
            Task {
                await handleSaveProfile(editProfile: editProfile, selectedFiles: selectedFiles)
            }
        }
    }
    
    private func getMyProfileInfo() {
        let savedProfile = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self)
        if let savedProfile = savedProfile {
            model.profile = savedProfile
            print("저장된 프로필: \(savedProfile)")
            // View 필드 데이터 업데이트
            model.nick = savedProfile.nick
            model.introduction = savedProfile.introduction ?? ""
            model.phoneNum = savedProfile.phoneNum ?? ""
            // 닉네임 유효성 검사
            validateNickname(savedProfile.nick)
        } else {
            // UserDefaults에 저장된 데이터가 없으면 네트워크에서 가져오기
            Task {
                await fetchMyProfileInfo()
            }
        }
    }
    
    private func fetchMyProfileInfo() async {
        do {
            let profile = try await repository.getMyProfileInfo()
            model.profile = profile
            
            // View 필드 데이터 업데이트
            model.nick = profile.nick
            model.introduction = profile.introduction ?? ""
            model.phoneNum = profile.phoneNum ?? ""
            // 닉네임 유효성 검사
            validateNickname(profile.nick)
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }
    
    private func saveProfile(editProfile: EditProfileRequestEntity) async {
        do {
            let profile = try await repository.editProfile(editProfile: editProfile)
            model.profile = profile
            print("프로필 저장 완료: \(profile)")
            // View 필드 데이터 업데이트
            model.nick = profile.nick
            model.introduction = profile.introduction ?? ""
            model.phoneNum = profile.phoneNum ?? ""
            
            // 프로필 수정 성공 시 MyPageView에 알림 전송
            NotificationCenter.default.post(name: .profileUpdated, object: profile)
            
            // 성공 토스트 메시지 표시
            model.toast = FancyToast(
                type: .success,
                title: "성공",
                message: "프로필이 성공적으로 저장되었습니다",
                duration: 3.0
            )
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }
    
    private func handleSaveProfile(editProfile: EditProfileRequestEntity, selectedFiles: [SelectedFile]) async {
        model.isLoading = true
        
        if let firstFile = selectedFiles.first {
            do {
                // 1. SelectedFile을 FileData로 변환
                guard let fileData = firstFile.toFileData() else {
                    model.errorMessage = "프로필 이미지 변환에 실패했습니다."
                    model.isLoading = false
                    return
                }
                
                // 2. 파일 검증
                if !FileManageHelper.shared.validateFile(fileData, uploadType: FileUploadType.profile) {
                    model.errorMessage = "프로필 이미지가 유효하지 않습니다. (1MB 이하, jpg/png/jpeg만 가능)"
                    model.isLoading = false
                    return
                }
                
                // 3. 이미지 업로드
                let uploadedImage = try await repository.uploadProfileImage(image: fileData)
                
                // 4. 업로드된 이미지 정보를 모델에 저장 (UI 업데이트용)
                model.profileImage = uploadedImage
                
                // 5. 프로필 정보 업데이트 (업로드된 이미지 경로 포함)
                let updatedEditProfile = EditProfileRequestEntity(
                    nick: editProfile.nick,
                    introduction: editProfile.introduction,
                    phoneNum: editProfile.phoneNum,
                    profileImage: uploadedImage.profileImage  // String 타입의 이미지 경로
                )
                print("업로드된 이미지 정보: \(uploadedImage.profileImage)")
                await saveProfile(editProfile: updatedEditProfile)
                
            } catch {
                model.errorMessage = error.localizedDescription
            }
        } else {
            // 이미지 없이 프로필 정보만 업데이트
            await saveProfile(editProfile: editProfile)
        }
        
        model.isLoading = false
    }
    
    // MARK: - 파일 검증
    private func validateFiles(_ files: [SelectedFile]) {
        let maxFileSize = 1 * 1024 * 1024 // 1MB
        let allowedExtensions = ["jpg", "jpeg", "png"]
        
        var newInvalidIndices: Set<Int> = []
        var newInvalidReasons: [Int: String] = [:]
        
        for (index, file) in files.enumerated() {
            let fileData = file.data ?? file.image?.jpegData(compressionQuality: 0.8) ?? Data()
            let fileExtension = file.fileExtension.lowercased()
            
            // 크기 검증
            let isSizeValid = fileData.count <= maxFileSize
            // 확장자 검증
            let isExtensionValid = allowedExtensions.contains(fileExtension)
            
            if !isSizeValid || !isExtensionValid {
                newInvalidIndices.insert(index)
                
                // 구체적인 원인 감지
                var reasons: [String] = []
                if !isSizeValid {
                    let formatter = ByteCountFormatter()
                    formatter.allowedUnits = [.useKB, .useMB]
                    formatter.countStyle = .file
                    let fileSizeString = formatter.string(fromByteCount: Int64(fileData.count))
                    let maxSizeString = formatter.string(fromByteCount: Int64(maxFileSize))
                    reasons.append("크기: \(fileSizeString) (제한: \(maxSizeString))")
                }
                if !isExtensionValid {
                    reasons.append("확장자: \(fileExtension.uppercased()) (지원: JPG, PNG)")
                }
                
                newInvalidReasons[index] = reasons.joined(separator: ", ")
                
                print("❌ 유효하지 않은 파일: \(file.fileName)")
                print("   - 원인: \(reasons.joined(separator: ", "))")
            }
        }
        
        // 유효하지 않은 파일 정보 업데이트
        model.invalidFileIndices = newInvalidIndices
        model.invalidFileReasons = newInvalidReasons
        
        // 유효하지 않은 파일이 새로 추가된 경우 토스트 표시를 위한 상태 업데이트
        if !newInvalidIndices.isEmpty {
            model.toast = FancyToast(
                type: .error,
                title: "파일 오류",
                message: "파일 크기가 너무 큽니다. 1MB 이하의 이미지를 선택해주세요.",
                duration: 3.0
            )
            print("⚠️ 유효하지 않은 파일이 감지되었습니다: \(newInvalidIndices.count)개")
        }
    }
    
    private func validateNickname(_ nickname: String) {
        if ValidationManager.shared.isValidNick(nickname) {
            model.isNicknameValid = true
            model.nicknameValidationMessage = "사용 가능한 닉네임입니다"
        } else {
            model.isNicknameValid = false
            model.nicknameValidationMessage = "닉네임에 특수문자(.,?*@-)를 포함할 수 없습니다"
        }
    }
}
