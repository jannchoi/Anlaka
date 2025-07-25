import Foundation

struct DeviceTokenRequestDTO: Codable {
    let deviceToken: String
}

// UpdateDeviceTokenResponseDTO는 EmptyResponseDTO를 사용
typealias UpdateDeviceTokenResponseDTO = EmptyResponseDTO

struct UpdateDeviceTokenResponseEntity {
    let success: Bool
    
    init(success: Bool = true) {
        self.success = success
    }
}
