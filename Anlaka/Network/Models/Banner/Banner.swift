import Foundation

// MARK: - Banner Response DTO
struct BannerResponseDTO: Codable {
    let name: String?
    let imageUrl: String?
    let payload: BannerPayloadDTO?
    
    func entity() -> BannerResponseEntity? {
        guard let name = name,
              let imageUrl = imageUrl,
              let payload = payload,
              let payloadEntity = payload.entity() else {
            return nil
        }
        
        return BannerResponseEntity(
            name: name,
            imageUrl: imageUrl,
            payload: payloadEntity
        )
    }
}

// MARK: - Banner Payload DTO
struct BannerPayloadDTO: Codable {
    let type: String?
    let value: String?
    
    func entity() -> BannerPayloadEntity? {
        guard let type = type,
              let value = value else {
            return nil
        }
        
        return BannerPayloadEntity(
            type: type,
            value: value
        )
    }
}

// MARK: - Banner List Response DTO
struct BannerListResponseDTO: Codable {
    let data: [BannerResponseDTO]?
    
    func entity() -> BannerListResponseEntity? {
        guard let data = data else {
            return nil
        }
        
        let entities = data.compactMap { $0.entity() }
        return BannerListResponseEntity(data: entities)
    }
}

// MARK: - Banner Response Entity
struct BannerResponseEntity {
    let name: String
    let imageUrl: String
    let payload: BannerPayloadEntity
}

// MARK: - Banner Payload Entity
struct BannerPayloadEntity {
    let type: String
    let value: String
}

// MARK: - Banner List Response Entity
struct BannerListResponseEntity {
    let data: [BannerResponseEntity]
}