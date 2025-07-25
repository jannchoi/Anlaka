//
//  ImageLoader.swift
//  Anlaka
//
//  Created by 최정안 on 5/31/25.
//

import Foundation
import UIKit
import ImageIO

// MARK: - 이미지 로더 전용 컨텍스트 정의
enum ImageLoaderContext: String {
    case thumbnail = "thumbnail"
    case listCell = "listCell"
    case detail = "detail"
    case poi = "poi"
    case profile = "profile"
}

// MARK: - 이미지 로더 전용 다운샘플링 정책
struct ImageLoaderDownsamplingPolicy {
    static let targetPixelSizeThumbnail: CGFloat = 332  // 166pt × 2x scale
    static let targetPixelSizeListCell: CGFloat = 300   // 150pt × 2x scale
    static let targetPixelSizeDetail: CGFloat = 750     // 375pt × 2x scale
    static let targetPixelSizePOI: CGFloat = 80         // 40pt × 2x scale
    static let targetPixelSizeProfile: CGFloat = 96     // 48pt × 2x scale
}

// MARK: - 이미지 로더 전용 캐시 정책
struct ImageLoaderCachePolicy {
    static let preloadLimit = 10
    static let cacheExpiration: TimeInterval = 5 * 60 // 5분 (데이터 캐시와 동일)
}

// MARK: - 이미지 에러 정의
enum ImageLoaderError: Error, LocalizedError {
    case invalidImageData
    case invalidImageFormat
    case cgImageCreationFailed
    case downsamplingFailed
    case networkError(String)
    case imageTooLarge
    case unsupportedImageType
    case tokenRefreshRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "유효하지 않은 이미지 데이터"
        case .invalidImageFormat:
            return "지원하지 않는 이미지 포맷"
        case .cgImageCreationFailed:
            return "CGImage 생성 실패"
        case .downsamplingFailed:
            return "이미지 다운샘플링 실패"
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .imageTooLarge:
            return "이미지가 너무 큽니다"
        case .unsupportedImageType:
            return "지원하지 않는 이미지 타입"
        case .tokenRefreshRequired:
            return "토큰 갱신이 필요합니다"
        }
    }
}

// MARK: - 이미지 로더 클래스 (NetworkManager와 통합)
class ImageLoader {
    static let shared = ImageLoader()
    
    private init() {}
    
    /// 이미지 로드 (비동기) - NetworkManager와 통합
    /// - Parameters:
    ///   - imagePath: 이미지 경로 (상대 경로)
    ///   - context: 이미지 사용 컨텍스트
    ///   - targetSize: 목표 크기 (선택사항)
    /// - Returns: 로드된 UIImage 또는 nil
    func loadImage(
        from imagePath: String,
        context: ImageLoaderContext = .listCell,
        targetSize: CGSize? = nil
    ) async -> UIImage? {
        
        // 빈 경로 체크
        guard !imagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [ImageLoader] imagePath가 빈 문자열입니다")
            return nil
        }
        
        // 1. 메모리 캐시 확인 (타임아웃 증가)
        let cacheKey = "\(imagePath)_\(context.rawValue)"
        let cachedImage = await withTimeout(seconds: 8.0) {
            try await ImageCache.shared.imageAsync(forKey: cacheKey)
        }
        if let cachedImage1 = cachedImage, let cachedImage2 = cachedImage1 {
            // 캐시된 이미지 유효성 검사
            if cachedImage2.size.width > 0 && cachedImage2.size.height > 0 && cachedImage2.cgImage != nil {
                return cachedImage2
            } else {
                // 유효하지 않은 이미지는 캐시에서 제거
                Task.detached {
                    await ImageCache.shared.removeImageAsync(forKey: cacheKey)
                }
            }
        }
        
        // 2. 디스크 캐시 확인 (타임아웃 증가)
        let diskCachedImage = await withTimeout(seconds: 8.0) {
            try await SafeDiskCacheManager.shared.loadImage(forKey: cacheKey)
        }
        if let diskCachedImage1 = diskCachedImage, let diskCachedImage2 = diskCachedImage1 {
            // 디스크 캐시된 이미지 유효성 검사
            if diskCachedImage2.size.height > 0 && diskCachedImage2.size.height > 0 && diskCachedImage2.cgImage != nil {
                // 메모리 캐시에도 저장
                Task.detached {
                    await ImageCache.shared.setImageAsync(diskCachedImage2, forKey: cacheKey)
                }
                
                return diskCachedImage2
            } else {
                // 유효하지 않은 이미지는 디스크 캐시에서 제거 (별도 Task로)
                Task.detached {
                    // 디스크 캐시 제거 로직 (필요시 구현)
                }
            }
        }
        
        // 3. 네트워크에서 다운로드 (NetworkManager와 통합)
        do {
            let downloadedImage = try await downloadImageWithNetworkManager(
                imagePath: imagePath,
                context: context
            )
            
            if let downloadedImage = downloadedImage {
                // 캐시에 저장 (별도 Task로 분리하여 성능 향상)
                Task.detached {
                    await ImageCache.shared.setImageAsync(downloadedImage, forKey: cacheKey)
                    await SafeDiskCacheManager.shared.saveImage(downloadedImage, forKey: cacheKey)
                }
                
                return downloadedImage
            }
        } catch {
            print("❌ 이미지 다운로드 실패: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// NetworkManager를 통한 이미지 다운로드 (토큰 갱신 로직 적용)
    private func downloadImageWithNetworkManager(
        imagePath: String,
        context: ImageLoaderContext
    ) async throws -> UIImage? {
        
        // NetworkManager를 통해 이미지 다운로드 (토큰 갱신 로직 포함)
        let result = try await NetworkManager.shared.downloadFile(from: imagePath)
        
        // 이미지 유효성 검사
        guard let image = result.image else {
            throw ImageLoaderError.invalidImageData
        }
        
        // 다운샘플링 적용
        let downsampledImage = downsampleImage(image, context: context)
        
        return downsampledImage
    }
    
    /// 이미지 다운샘플링
    private func downsampleImage(_ image: UIImage, context: ImageLoaderContext) -> UIImage {
        let targetSize: CGFloat
        
        switch context {
        case .thumbnail:
            targetSize = ImageLoaderDownsamplingPolicy.targetPixelSizeThumbnail
        case .listCell:
            targetSize = ImageLoaderDownsamplingPolicy.targetPixelSizeListCell
        case .detail:
            targetSize = ImageLoaderDownsamplingPolicy.targetPixelSizeDetail
        case .poi:
            targetSize = ImageLoaderDownsamplingPolicy.targetPixelSizePOI
        case .profile:
            targetSize = ImageLoaderDownsamplingPolicy.targetPixelSizeProfile
        }
        
        // 다운샘플링이 필요한지 확인
        let originalSize = image.size
        let originalScale = image.scale
        let originalPixelSize = CGSize(
            width: originalSize.width * originalScale,
            height: originalSize.height * originalScale
        )
        
        let targetPixelSize = CGSize(width: targetSize, height: targetSize)
        
        // 다운샘플링이 필요한지 확인 (원본이 목표보다 1.2배 이상 클 때)
        let shouldDownsample = originalPixelSize.width > targetPixelSize.width * 1.2 ||
                              originalPixelSize.height > targetPixelSize.height * 1.2
        
        guard shouldDownsample else { return image }
        
        // 다운샘플링 수행
        let maxDimension = max(targetPixelSize.width, targetPixelSize.height)
        
        guard let cgImage = image.cgImage else { return image }
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        
        guard let imageSource = CGImageSourceCreateWithData(image.jpegData(compressionQuality: 1.0) as! CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return image
        }
        
        return UIImage(cgImage: thumbnail, scale: UIScreen.main.scale, orientation: image.imageOrientation)
    }
    
    /// 타임아웃을 포함한 비동기 작업 래퍼 (메모리 안전)
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async -> T? {
        do {
            return try await withThrowingTaskGroup(of: T?.self) { group in
                // 메인 작업
                group.addTask {
                    do {
                        return try await operation()
                    } catch {
                        return nil
                    }
                }
                
                // 타임아웃 작업
                group.addTask {
                    do {
                        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                    } catch {
                        // 에러 무시
                    }
                    return nil
                }
                
                // 결과 처리
                for try await result in group {
                    if let result = result {
                        group.cancelAll() // 타임아웃 처리시 다른 태스크 취소
                        return result
                    }
                }
                
                return nil
            }
        } catch {
            return nil
        }
    }
    
    /// 이미지 프리로딩 (NetworkManager와 통합)
    static func preloadImages(_ imagePaths: [String]) {
        let preloadLimit = ImageLoaderCachePolicy.preloadLimit
        
        // 프리로딩 제한을 적용하여 과도한 네트워크 요청 방지
        let limitedPaths = Array(imagePaths.prefix(preloadLimit))
        
        for path in limitedPaths {
            // 빈 경로 체크
            guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("⚠️ [ImageLoader] 프리로딩할 path가 빈 문자열입니다")
                continue
            }
            
            // 메모리 캐시에 없고 디스크 캐시에도 없는 경우에만 프리로딩
            Task {
                let memoryImage = await ImageCache.shared.imageAsync(forKey: path)
                let diskImage = await SafeDiskCacheManager.shared.loadImage(forKey: path)
                
                if memoryImage == nil && diskImage == nil {
                    // NetworkManager를 통해 프리로딩
                    do {
                        let result = try await NetworkManager.shared.downloadFile(from: path)
                        if let image = result.image {
                            // 캐시에 저장 (thumbnail 컨텍스트로 저장)
                            let cacheKey = "\(path)_thumbnail"
                            await ImageCache.shared.setImageAsync(image, forKey: cacheKey)
                            await SafeDiskCacheManager.shared.saveImage(image, forKey: cacheKey)
                        }
                    } catch {
                        print("❌ 이미지 프리로딩 실패: \(path) - \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// MARK: - 편의 메서드들
extension ImageLoader {
    /// POI용 이미지 로드
    func loadPOIImage(from imagePath: String) async -> UIImage? {
        let result = await loadImage(from: imagePath, context: .poi)
        if result == nil {
            print("❌ [ImageLoader] POI 이미지 로드 실패: \(imagePath)")
        }
        return result
    }
    
    /// 썸네일용 이미지 로드
    func loadThumbnailImage(from imagePath: String) async -> UIImage? {
        return await loadImage(from: imagePath, context: .thumbnail)
    }
    
    /// 리스트 셀용 이미지 로드
    func loadListCellImage(from imagePath: String) async -> UIImage? {
        return await loadImage(from: imagePath, context: .listCell)
    }
    
    /// 상세 페이지용 이미지 로드
    func loadDetailImage(from imagePath: String) async -> UIImage? {
        return await loadImage(from: imagePath, context: .detail)
    }
    
    /// 프로필용 이미지 로드
    func loadProfileImage(from imagePath: String) async -> UIImage? {
        return await loadImage(from: imagePath, context: .profile)
    }
} 
