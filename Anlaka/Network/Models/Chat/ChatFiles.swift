

struct ChatFilesRequestDTO: Codable {
    let files: [String]
}

struct ChatFileResponseDTO: Codable {
    let files: [String]
    
    func toEntity() -> ChatFileEntity {
        return ChatFileEntity(files: files)
    }
}

struct ChatFileEntity {
    let files: [String]
    
    func toDTO() -> ChatFilesRequestDTO {
        return ChatFilesRequestDTO(files: files)
    }
}
