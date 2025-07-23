import Foundation

struct SearchUserResponseDTO: Codable {
    let data: [OtherProfileInfoDTO]
}

struct SearchUserEntity: Codable {
    let data: [OtherProfileInfoEntity]
}

extension SearchUserResponseDTO {
    func toEntity() -> SearchUserEntity {
        return SearchUserEntity(data: data.compactMap { $0.toEntity() })
    }
}