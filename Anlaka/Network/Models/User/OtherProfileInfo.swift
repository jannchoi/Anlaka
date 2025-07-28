import Foundation

struct OtherProfileInfoDTO: Codable {
    let userid: String?
    let nick: String?
    let profileImage: String?
    let introduction: String?
    enum CodingKeys: String, CodingKey {
        case userid = "user_id"
        case nick, profileImage, introduction
    }   
}

struct OtherProfileInfoEntity: Codable {
    let userid: String
    let nick: String
    let profileImage: String?
    let introduction: String
}

extension OtherProfileInfoDTO {
    func toEntity() -> OtherProfileInfoEntity? {
        guard let userid = userid, let nick = nick else {
            print(" 사용자 ID가 비어있습니다. userid: \(userid ?? "nil"), nick: \(nick ?? "nil")")
            return nil
        }
        return OtherProfileInfoEntity(
            userid: userid,
            nick: nick,
            profileImage: profileImage,
            introduction: introduction ?? ""
        )
    }
}
