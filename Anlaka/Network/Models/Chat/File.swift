//
//  File.swift
//  Anlaka
//
//  Created by 최정안 on 6/10/25.
//

import SwiftUI
// MARK: - Gallery Image (갤러리에서 선택한 이미지)
struct GalleryImage {
    let image: UIImage
    let fileName: String
}

// MARK: - Selected File (FilePicker에서 선택된 파일)
enum FileType {
    case image
    case video
    case pdf
}

struct SelectedFile {
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
}

extension GalleryImage {
    func toEntity() -> FileEntity {
        // 로컬 이미지이므로 URL은 placeholder로 사용하거나 file:// 구성 가능
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        return FileEntity(previewImage: image, path: fileURL.path)
    }
}

// MARK: - DTO (서버 통신용)
struct FileDTO {
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
struct FileEntity {
    let previewImage: UIImage
    let path: String
    
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
struct FileDB {
    let files: [String]
}

extension FileDB {
    func toEntity() -> [FileEntity] {
        return files.map {
            return FileEntity(previewImage: UIImage(), path: $0)
        }
    }
}
