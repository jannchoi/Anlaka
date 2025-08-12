import UIKit
import AVFoundation
import ImageIO

class ThumbnailExtractor {
    static let shared = ThumbnailExtractor()
    
    private init() {}
    
    // MARK: - 비디오 썸네일 추출
    func extractVideoThumbnail(from url: URL, at time: CMTime = .zero) async -> UIImage? {
        let asset = AVAsset(url: url)
        let fileExtension = url.pathExtension.lowercased()
        
        // 비디오 트랙 확인
        let tracks = try? await asset.loadTracks(withMediaType: .video)
        guard let videoTracks = tracks, !videoTracks.isEmpty else {
            print("⚠️ [ThumbnailExtractor] \(fileExtension.uppercased()) 비디오 트랙을 찾을 수 없습니다")
            return nil
        }
        
        do {
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 300, height: 300)
            
            // 포맷별 최적화된 설정
            switch fileExtension {
            case "mov":
                // MOV: 관대한 시간 허용 오차
                imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 1)
                imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 1)
            case "avi", "mkv", "wmv":
                // AVI/MKV/WMV: 매우 관대한 설정 (제한적 지원)
                imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 2, preferredTimescale: 1)
                imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 2, preferredTimescale: 1)
                imageGenerator.maximumSize = CGSize(width: 200, height: 200) // 더 작은 크기
            default:
                // MP4 등: 정확한 시간 설정
                imageGenerator.requestedTimeToleranceBefore = .zero
                imageGenerator.requestedTimeToleranceAfter = .zero
            }
            
            // 첫 번째 시도: 0초에서 추출
            let cgImage = try await imageGenerator.image(at: time).image

            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ [ThumbnailExtractor] \(fileExtension.uppercased()) 첫 번째 시도 실패: \(error)")
            
            // 두 번째 시도: 다른 시간에서 추출
            do {
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                imageGenerator.maximumSize = CGSize(width: 300, height: 300)
                
                // 포맷별 대체 설정
                switch fileExtension {
                case "avi", "mkv", "wmv":
                    // AVI/MKV/WMV: 매우 관대한 설정
                    imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 5, preferredTimescale: 1)
                    imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 5, preferredTimescale: 1)
                    imageGenerator.maximumSize = CGSize(width: 150, height: 150)
                default:
                    imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 1, preferredTimescale: 1)
                    imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 1)
                }
                
                // 1초 지점에서 추출 시도
                let alternativeTime = CMTime(seconds: 1, preferredTimescale: 1)
                let cgImage = try await imageGenerator.image(at: alternativeTime).image

                return UIImage(cgImage: cgImage)
            } catch {
                print("❌ [ThumbnailExtractor] \(fileExtension.uppercased()) 대체 시간에서도 추출 실패: \(error)")
                
                // 세 번째 시도: 가장 관대한 설정으로 추출
                do {
                    let imageGenerator = AVAssetImageGenerator(asset: asset)
                    imageGenerator.appliesPreferredTrackTransform = true
                    imageGenerator.maximumSize = CGSize(width: 100, height: 100) // 가장 작은 크기
                    imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 10, preferredTimescale: 1)
                    imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 10, preferredTimescale: 1)
                    
                    let cgImage = try await imageGenerator.image(at: .zero).image

                    return UIImage(cgImage: cgImage)
                } catch {
                    print("❌ [ThumbnailExtractor] \(fileExtension.uppercased()) 모든 시도 실패: \(error)")
                    return nil
                }
            }
        }
    }
    
    // MARK: - GIF 썸네일 추출 (첫 번째 프레임)
    func extractGIFThumbnail(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("❌ [ThumbnailExtractor] GIF 소스 생성 실패")
            return nil
        }
        
        let count = CGImageSourceGetCount(source)
        guard count > 0 else {
            print("❌ [ThumbnailExtractor] GIF 프레임이 없습니다")
            return nil
        }
        
        // 첫 번째 프레임 추출
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            print("❌ [ThumbnailExtractor] GIF 첫 번째 프레임 추출 실패")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - 네트워크 URL에서 썸네일 추출
    func extractThumbnailFromURL(_ urlString: String, fileType: FileType) async -> UIImage? {
        // BaseURL과 결합하여 전체 URL 생성
        let fullURLString = BaseURL.baseV1 + urlString
        
        guard let url = URL(string: fullURLString) else {
            print("❌ [ThumbnailExtractor] 유효하지 않은 URL: \(fullURLString)")
            return nil
        }
        
        // URLRequest 생성 및 헤더 설정
        var request = URLRequest(url: url)
        request.addValue(AppConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        if let accessToken = KeychainManager.shared.getString(forKey: .accessToken) {
            request.addValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // HTTP 응답 상태 확인
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ [ThumbnailExtractor] HTTP 오류: \(response)")
                return nil
            }
            
            switch fileType {
            case .video:
                // 원본 파일 확장자에 따라 임시 파일 생성
                let fileExtension = URL(string: urlString)?.pathExtension.lowercased() ?? "mp4"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "." + fileExtension)
                try data.write(to: tempURL)
                defer { 
                    try? FileManager.default.removeItem(at: tempURL)
                }
                
                let thumbnail = await extractVideoThumbnail(from: tempURL)
                if thumbnail != nil {
                } else {
                    print("❌ [ThumbnailExtractor] \(fileExtension.uppercased()) 썸네일 추출 실패: \(urlString)")
                }
                return thumbnail
                
            case .gif:
                let thumbnail = extractGIFThumbnail(from: data)
                if thumbnail != nil {
                } else {
                    print("❌ [ThumbnailExtractor] GIF 썸네일 추출 실패: \(urlString)")
                }
                return thumbnail
                
            default:
                let thumbnail = UIImage(data: data)
                if thumbnail != nil {
                } else {
                    print("❌ [ThumbnailExtractor] 이미지 로드 실패: \(urlString)")
                }
                return thumbnail
            }
        } catch {
            print("❌ [ThumbnailExtractor] 네트워크 요청 실패: \(error)")
            return nil
        }
    }
    
    // MARK: - 파일 타입 열거형
    enum FileType {
        case video
        case gif
        case image
    }
}

// MARK: - 파일 확장자별 타입 판별
extension ThumbnailExtractor {
    static func getFileType(from urlString: String) -> FileType {
        let fileExtension = URL(string: urlString)?.pathExtension.lowercased() ?? ""
        
        switch fileExtension {
        case "mp4", "mov", "avi", "mkv", "wmv":
            return .video
        case "gif":
            return .gif
        case "jpg", "jpeg", "png", "webp":
            return .image
        default:
            return .image
        }
    }
} 