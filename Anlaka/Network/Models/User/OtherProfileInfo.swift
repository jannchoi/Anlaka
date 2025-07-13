import Foundation

struct OtherProfileInfoDTO: Codable {
    let userid: String?
    let nick: String?
    let profileImage: String?
    let introduction: String?
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
