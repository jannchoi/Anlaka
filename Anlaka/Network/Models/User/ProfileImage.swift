import Foundation

struct ProfileImageDTO: Codable {
    let profileImage: String?
}

struct ProfileImageEntity: Codable {
    let profileImage: String
}

extension ProfileImageDTO {
    func toEntity() -> ProfileImageEntity? {
        guard let profileImage = profileImage else {
            return nil
        }
        return ProfileImageEntity(profileImage: profileImage)
    }
}