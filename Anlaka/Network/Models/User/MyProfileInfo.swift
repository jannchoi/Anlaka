import Foundation

struct MyProfileInfoDTO: Codable {
    let userid: String
    let email: String
    let nick: String
    let profileImage: String?
    let phoneNum: String?
    let introduction: String?
}

// MARK: - MyProfileInfoEntity
struct MyProfileInfoEntity: Codable {
    let userid: String
    let email: String
    let nick: String
    let profileImage: String?
    let phoneNum: String?
    let introduction: String?
}   

// MARK: - Extension
extension MyProfileInfoDTO {
    func toEntity() -> MyProfileInfoEntity {
        return MyProfileInfoEntity(
            userid: userid,
            email: email,
            nick: nick,
            profileImage: profileImage,
            phoneNum: phoneNum,
            introduction: introduction
        )
    }
}