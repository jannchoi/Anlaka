import Foundation

struct MyProfileInfoDTO: Codable {
    let userid: String?
    let email: String?
    let nick: String?
    let profileImage: String?
    let phoneNum: String?
    let introduction: String?
    enum CodingKeys: String, CodingKey {
        case userid = "user_id"
        case email = "email"
        case nick = "nick"
        case profileImage = "profileImage"
        case phoneNum = "phoneNum"
        case introduction = "introduction"
    }
    
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
    func toEntity() -> MyProfileInfoEntity? {
        guard let userid = userid, let email = email, let nick = nick else {
            return nil
        }
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
extension MyProfileInfoEntity {
    func toUserInfoEntity() -> UserInfoEntity {
        return UserInfoEntity(userId: userid, nick: nick, introduction: introduction ?? "", profileImage: profileImage ?? "")
    }
}
