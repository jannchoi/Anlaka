//
//  File.swift
//  Anlaka
//
//  Created by 최정안 on 6/10/25.
//

import SwiftUI

// MARK: - Server File Entity (서버에서 다운로드한 파일용)
struct ServerFileEntity: Equatable, Hashable {
    let serverPath: String      // 서버 상대경로 (ex: "/data/posts/image_1712739634962.png")
    var localPath: String?      // 로컬에 다운로드된 파일 경로 (다운로드 완료 후 설정)
    let fileName: String        // 파일명
    let fileExtension: String   // 파일 확장자
    let mimeType: String        // MIME 타입
    var isDownloaded: Bool      // 다운로드 완료 여부
    var image: UIImage?         // 이미지인 경우 UIImage (메모리 효율을 위해 필요시에만 로드)
    
    init(serverPath: String) {
        self.serverPath = serverPath
        self.localPath = nil
        self.fileName = (serverPath as NSString).lastPathComponent
        self.fileExtension = (serverPath as NSString).pathExtension.lowercased()
        self.mimeType = Self.getMimeType(for: self.fileExtension)
        self.isDownloaded = false
        self.image = nil
    }
    
    // 다운로드 완료 후 호출
    mutating func setDownloaded(localPath: String, image: UIImage? = nil) {
        self.localPath = localPath
        self.isDownloaded = true
        self.image = image
    }
    
    // MIME 타입 결정
    private static func getMimeType(for fileExtension: String) -> String {
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
    
    // Equatable 구현
    static func == (lhs: ServerFileEntity, rhs: ServerFileEntity) -> Bool {
        return lhs.serverPath == rhs.serverPath
    }
    
    // Hashable 구현
    func hash(into hasher: inout Hasher) {
        hasher.combine(serverPath)
    }
}

// MARK: - ServerFileEntity Extensions
extension ServerFileEntity {
    // 파일 다운로드 상태
    enum DownloadState {
        case notStarted
        case downloading
        case downloaded
        case failed(Error)
    }
    
    // 다운로드 상태를 추적하는 래퍼
    struct DownloadableFile {
        var file: ServerFileEntity
        var downloadState: DownloadState = .notStarted
        
        init(serverPath: String) {
            self.file = ServerFileEntity(serverPath: serverPath)
        }
        
        mutating func setDownloading() {
            downloadState = .downloading
        }
        
        mutating func setDownloaded(localPath: String, image: UIImage? = nil) {
            file.setDownloaded(localPath: localPath, image: image)
            downloadState = .downloaded
        }
        
        mutating func setFailed(_ error: Error) {
            downloadState = .failed(error)
        }
    }
}

// MARK: - Gallery Image (갤러리에서 선택한 이미지)
struct GalleryImage: Equatable {
    let image: UIImage
    let fileName: String
    
    // Equatable 구현
    static func == (lhs: GalleryImage, rhs: GalleryImage) -> Bool {
        return lhs.fileName == rhs.fileName
        // UIImage는 비교하지 않음 (성능상의 이유)
    }
}

// MARK: - Selected File (FilePicker에서 선택된 파일)
enum FileType: Equatable {
    case image
    case video
    case pdf
}

struct SelectedFile: Equatable {
    let fileName: String
    let fileType: FileType
    let image: UIImage?     // 이미지용
    let data: Data?         // PDF, 비디오용
    
    var fileExtension: String {
        return (fileName as NSString).pathExtension.lowercased()
    }
    
    var mimeType: String {
        switch fileExtension {
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

extension SelectedFile {
    func toFileData() -> FileData? {
        switch fileType {
        case .image:
            guard let image = image else { return nil }
            return FileData(
                data: image.jpegData(compressionQuality: 0.8) ?? Data(),
                fileName: fileName,
                mimeType: mimeType,
                fileExtension: fileExtension
            )
        case .video, .pdf:
            guard let data = data else { return nil }
            return FileData(
                data: data,
                fileName: fileName,
                mimeType: mimeType,
                fileExtension: fileExtension
            )
        }
    }
    
    // Equatable 구현
    static func == (lhs: SelectedFile, rhs: SelectedFile) -> Bool {
        return lhs.fileName == rhs.fileName &&
               lhs.fileType == rhs.fileType &&
               lhs.fileExtension == rhs.fileExtension &&
               lhs.mimeType == rhs.mimeType
        // UIImage와 Data는 비교하지 않음 (성능상의 이유)
    }
}

extension GalleryImage {
    func toEntity() -> FileEntity {
        // 로컬 이미지이므로 URL은 placeholder로 사용하거나 file:// 구성 가능
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        return FileEntity(previewImage: image, path: fileURL.path)
    }
}

// MARK: - DTO (서버 통신용)
struct FileDTO: Decodable {
    let files: [String]?
    
    init(files: [String]? = nil) {
        self.files = files
    }
}
struct FileRequestDTO: Decodable {
    let files: [String]
}

extension FileDTO {
    func toEntity() -> [FileEntity] {
        guard let files else { return [] }
        return files.map {
            return FileEntity(previewImage: UIImage(), path: $0)
        }
    }
    
    func toDB() -> FileDB {
        return FileDB(files: files ?? [])
    }
}

// MARK: - Entity (UI 표시용)
struct FileEntity: Equatable {
    let previewImage: UIImage
    let path: String
    
    // Equatable 구현
    static func == (lhs: FileEntity, rhs: FileEntity) -> Bool {
        return lhs.path == rhs.path
        // UIImage는 비교하지 않음 (성능상의 이유)
    }
}

extension FileEntity {
    func toDTO() -> FileDTO {
        return FileDTO(files: [path])
    }

    func toDB() -> FileDB {
        return FileDB(files: [path])
    }
}

// MARK: - DB (데이터베이스 저장용)
struct FileDB: Equatable {
    let files: [String]
}

extension FileDB {
    func toEntity() -> [FileEntity] {
        return files.map {
            return FileEntity(previewImage: UIImage(), path: $0)
        }
    }
}


// ChattingView에서 사용할 뷰 전용 파일 모델 정의
struct ChattingSelectedFileViewModel: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let sizeMB: Double
    // 필요시 썸네일, 타입 등 추가
}

// ProfileView에서 사용할 뷰 전용 파일 모델 정의
struct ProfileSelectedFileViewModel: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let sizeMB: Double
    // 필요시 썸네일, 타입 등 추가
}


struct PostingSelectedFileViewModel: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let sizeMB: Double
}




// ProfileSelectedFileViewModel -> SelectedFile 변환 extension
extension ProfileSelectedFileViewModel {
    func toSelectedFile(with image: UIImage) -> SelectedFile {
        SelectedFile(
            fileName: self.name,
            fileType: .image,
            image: image,
            data: image.jpegData(compressionQuality: 0.8)
        )
    }
}
// 네트워크 SelectedFile -> PostingViewModel 변환 함수
extension SelectedFile {
    func toPostingViewModel() -> PostingSelectedFileViewModel {
        PostingSelectedFileViewModel(
            name: self.fileName,
            sizeMB: Double(self.data?.count ?? 0) / 1024.0 / 1024.0
        )
    }
}
// 네트워크 SelectedFile -> 뷰모델 변환 함수
extension SelectedFile {
    func toChattingViewModel() -> ChattingSelectedFileViewModel {
        ChattingSelectedFileViewModel(
            name: self.fileName,
            sizeMB: Double(self.data?.count ?? 0) / 1024.0 / 1024.0
        )
    }
}
// 네트워크 SelectedFile -> 뷰모델 변환 함수
extension SelectedFile {
    func toProfileViewModel() -> ProfileSelectedFileViewModel {
        ProfileSelectedFileViewModel(
            name: self.fileName,
            sizeMB: Double(self.data?.count ?? 0) / 1024.0 / 1024.0
        )
    }
}
extension SelectedFile {
    var sizeMB: Double {
        let dataSize = data?.count ?? image?.jpegData(compressionQuality: 0.8)?.count ?? 0
        return Double(dataSize) / 1024.0 / 1024.0
    }
}
