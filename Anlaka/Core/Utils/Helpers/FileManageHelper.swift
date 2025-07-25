
import UIKit
import Foundation

// MARK: - 파일 업로드 타입별 설정
enum FileUploadType: CaseIterable {
    case profile    // 프로필 이미지
    case chat       // 채팅 파일
    case community  // 커뮤니티 파일
    
    var allowedExtensions: [String] {
        switch self {
        case .profile:
            return ["jpg", "png", "jpeg"]
        case .chat:
            return ["jpg", "png", "jpeg", "gif", "pdf"]
        case .community:
            return ["jpg", "png", "jpeg", "gif", "webp", "mp4", "mov", "avi", "mkv", "wmv"]
        }
    }
    
    var maxFileSize: Int {
        switch self {
        case .profile:
            return 1 * 1024 * 1024 // 1MB
        case .chat, .community:
            return 5 * 1024 * 1024 // 5MB
        }
    }
    
    var maxFileCount: Int {
        switch self {
        case .profile:
            return 1
        case .chat, .community:
            return 5
        }
    }
    
    var fieldName: String {
        switch self {
        case .profile:
            return "profile"
        case .chat, .community:
            return "files"
        }
    }
}

// MARK: - 파일 데이터 모델
struct FileData {
    let data: Data
    let fileName: String
    let mimeType: String
    let fileExtension: String
    
    var isValidExtension: Bool {
        return FileUploadType.allCases.contains { type in
            type.allowedExtensions.contains(fileExtension.lowercased())
        }
    }
    
    var isValidSize: Bool {
        return FileUploadType.allCases.contains { type in
            data.count <= type.maxFileSize
        }
    }
}

// MARK: - FileManager
class FileManageHelper{
    static let shared = FileManageHelper()
    private init() {}
    
    // MARK: - 파일 변환 메서드들
    
    /// GalleryImage를 FileData로 변환
    func convertGalleryImage(_ galleryImage: GalleryImage, uploadType: FileUploadType) -> FileData? {
        guard let imageData = galleryImage.image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let fileExtension = (galleryImage.fileName as NSString).pathExtension.lowercased()
        
        return FileData(
            data: imageData,
            fileName: galleryImage.fileName,
            mimeType: "image/jpeg",
            fileExtension: fileExtension
        )
    }
    
    /// UIImage를 FileData로 변환
    func convertUIImage(_ image: UIImage, fileName: String, uploadType: FileUploadType) -> FileData? {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        // 확장자에 따라 적절한 포맷으로 변환
        let imageData: Data?
        let mimeType: String
        let finalExtension: String
        
        switch fileExtension {
        case "png":
            imageData = image.pngData()
            mimeType = "image/png"
            finalExtension = "png"
        case "webp":
            // WebP는 JPEG로 변환 (iOS에서 WebP 인코딩 지원 제한)
            imageData = image.jpegData(compressionQuality: 0.8)
            mimeType = "image/jpeg"
            finalExtension = "jpg"
        default:
            // jpg, jpeg, gif 등은 JPEG로 변환
            imageData = image.jpegData(compressionQuality: 0.8)
            mimeType = "image/jpeg"
            finalExtension = "jpg"
        }
        
        guard let data = imageData else {
            print("❌ [FileManageHelper] 이미지 데이터 변환 실패: \(fileName)")
            return nil
        }
        
        // 확장자가 없는 경우 기본값으로 처리 (이미 FilePicker에서 처리됨)
        let finalFileName = fileName
        
        return FileData(
            data: data,
            fileName: finalFileName,
            mimeType: mimeType,
            fileExtension: finalExtension
        )
    }
    
    /// Data를 FileData로 변환 (PDF, 비디오 등)
    func convertData(_ data: Data, fileName: String, uploadType: FileUploadType) -> FileData? {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        // 확장자가 없는 경우 기본값으로 처리 (이미 FilePicker에서 처리됨)
        let finalExtension = fileExtension
        let mimeType = getMimeType(for: finalExtension)
        let finalFileName = fileName
        
        return FileData(
            data: data,
            fileName: finalFileName,
            mimeType: mimeType,
            fileExtension: finalExtension
        )
    }
    
    // MARK: - 파일 검증
    
    /// 파일 유효성 검사
    func validateFile(_ fileData: FileData, uploadType: FileUploadType) -> Bool {
        // 확장자 검증
        guard uploadType.allowedExtensions.contains(fileData.fileExtension.lowercased()) else {
            print("❌ 허용되지 않는 파일 확장자: \(fileData.fileExtension)")
            return false
        }
        
        // 크기 검증
        guard fileData.data.count <= uploadType.maxFileSize else {
            print("❌ 파일 크기 초과: \(fileData.fileName) - \(fileData.data.count) bytes")
            return false
        }
        
        return true
    }
    
    /// 여러 파일 검증
    func validateFiles(_ fileDataArray: [FileData], uploadType: FileUploadType) -> [FileData] {
        // 파일 개수 제한
        let limitedFiles = Array(fileDataArray.prefix(uploadType.maxFileCount))
        
        // 각 파일 검증
        return limitedFiles.filter { fileData in
            validateFile(fileData, uploadType: uploadType)
        }
    }
    
    // MARK: - DTO 변환
    
    /// FileData 배열을 FileRequestDTO로 변환
    func convertToFileRequestDTO(_ fileDataArray: [FileData], uploadType: FileUploadType) -> FileRequestDTO {
        let fileNames = fileDataArray.map { $0.fileName }
        return FileRequestDTO(files: fileNames)
    }
    
    // MARK: - 유틸리티 메서드
    
    /// 파일 확장자에 따른 MIME 타입 반환
    private func getMimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "pdf":
            return "application/pdf"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        case "mkv":
            return "video/x-matroska"
        case "wmv":
            return "video/x-ms-wmv"
        default:
            return "application/octet-stream"
        }
    }
}
