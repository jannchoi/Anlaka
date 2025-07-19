

import Foundation

struct ChatFilesRequestDTO: Codable {
    let files: [ChatFile]
}
struct ChatFile: Codable {
    let data: Data           // 실제 파일 데이터
    let fileName: String     // 파일 이름
    let mimeType: String     // MIME 타입
    let fileExtension: String // 파일 확장자
    
    // 파일 확장자 검증
    var isValidExtension: Bool {
        let allowedExtensions = ["jpg", "jpeg", "png", "gif", "pdf"]
        return allowedExtensions.contains(fileExtension.lowercased())
    }
}

struct ChatFileResponseDTO: Codable {
    let files: [String?]
    
    func toEntity() -> ChatFileEntity {
        let fileEntities = files.compactMap { $0 }
        return ChatFileEntity(files: fileEntities)
    }
}

struct ChatFileEntity {
    let files: [String]

}
