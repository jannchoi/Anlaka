import Foundation

struct EditProfileModel {
    var errorMessage: String? = nil
    var profileImage: ProfileImageEntity? = nil
    var profile: MyProfileInfoEntity? = nil
    var isLoading: Bool = false
    var showSuccessToast: Bool = false
    
    // View에서 사용할 필드 데이터
    var nick: String = ""
    var introduction: String = ""
    var phoneNum: String = ""
}

enum EditProfileIntent {
    case initialRequest
    case saveProfile(EditProfileRequestEntity, Data?)
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
            Task {
                await getMyProfileInfo()
            }
        case .saveProfile(let editProfile, let profileImageData):
            Task {
                await handleSaveProfile(editProfile: editProfile, profileImageData: profileImageData)
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
            
            // 성공 토스트 메시지 표시
            model.showSuccessToast = true
            
            // 3초 후 토스트 메시지 숨기기
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.model.showSuccessToast = false
            }
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }

    private func handleSaveProfile(editProfile: EditProfileRequestEntity, profileImageData: Data?) async {
        model.isLoading = true
        
        if let profileImageData = profileImageData {
            do {
                // 1. 이미지 업로드
                let uploadedImage = try await repository.uploadProfileImage(image: profileImageData)
                
                // 2. 업로드된 이미지 정보를 모델에 저장 (UI 업데이트용)
                model.profileImage = uploadedImage
                
                // 3. 프로필 정보 업데이트 (업로드된 이미지 경로 포함)
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
} 