import Foundation

struct EditProfileRequestDTO: Codable {
    let nick: String?
    let introduction: String?
    let phoneNum: String?
    let profileImage: String?
}
struct EditProfileRequestEntity: Codable {
    let nick: String?
    let introduction: String?
    let phoneNum: String?
    let profileImage: String?
}
extension EditProfileRequestEntity {
    func toDTO() -> EditProfileRequestDTO {
        return EditProfileRequestDTO(nick: nick, introduction: introduction, phoneNum: phoneNum, profileImage: profileImage)
    }
}

// response는 MyProfileInfoDTO와 동일
