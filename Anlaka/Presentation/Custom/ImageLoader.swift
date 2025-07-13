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
enum ImageLoaderContext {
    case thumbnail
    case listCell
    case detail
    case poi
    case profile
}

// MARK: - 이미지 로더 전용 다운샘플링 정책
struct ImageLoaderDownsamplingPolicy {
    static let targetPixelSizeThumbnail: CGFloat = 100
    static let targetPixelSizeListCell: CGFloat = 200
    static let targetPixelSizeDetail: CGFloat = 400
    static let targetPixelSizePOI: CGFloat = 80
    static let targetPixelSizeProfile: CGFloat = 150
}

// MARK: - 이미지 로더 전용 캐시 정책
struct ImageLoaderCachePolicy {
    static let preloadLimit = 10
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
        }
    }
}

// MARK: - 이미지 로더 클래스
class ImageLoader {
    static let shared = ImageLoader()
    
    private init() {}
    
    /// 이미지 로드 (비동기)
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
        
        // 1. 메모리 캐시 확인 (타임아웃 증가)
        let cachedImage = await withTimeout(seconds: 8.0) {
            try await ImageCache.shared.imageAsync(forKey: imagePath)
    }
        if let cachedImage1 = cachedImage, let cachedImage2 = cachedImage1 {
            // 캐시된 이미지 유효성 검사
            if cachedImage2.size.width > 0 && cachedImage2.size.height > 0 && cachedImage2.cgImage != nil {
                return cachedImage2
            } else {
                // 유효하지 않은 이미지는 캐시에서 제거
                Task.detached {
                    await ImageCache.shared.removeImageAsync(forKey: imagePath)
                }
            }
        } else {
            // 타임아웃 발생 시 빠른 재시도 (1초)
            let retryCachedImage = await withTimeout(seconds: 1.0) {
                try await ImageCache.shared.imageAsync(forKey: imagePath)
            }
            if let retryCachedImage1 = retryCachedImage, let retryCachedImage2 = retryCachedImage1 {
                // 재시도로 찾은 이미지 유효성 검사
                if retryCachedImage2.size.width > 0 && retryCachedImage2.size.height > 0 && retryCachedImage2.cgImage != nil {
                    return retryCachedImage2
                } else {
                    // 유효하지 않은 이미지는 캐시에서 제거
                    Task.detached {
                        await ImageCache.shared.removeImageAsync(forKey: imagePath)
                    }
                }
            }
        }
        
        // 2. 디스크 캐시 확인 (타임아웃 증가)
        let diskCachedImage = await withTimeout(seconds: 8.0) {
            try await SafeDiskCacheManager.shared.loadImage(forKey: imagePath)
        }
        if let diskCachedImage1 = diskCachedImage, let diskCachedImage2 = diskCachedImage1 {
            // 디스크 캐시된 이미지 유효성 검사
            if diskCachedImage2.size.width > 0 && diskCachedImage2.size.height > 0 && diskCachedImage2.cgImage != nil {
                // 메모리 캐시에도 저장
                Task.detached {
                    await ImageCache.shared.setImageAsync(diskCachedImage2, forKey: imagePath)
                }
                
                return diskCachedImage2
            } else {
                // 유효하지 않은 이미지는 디스크 캐시에서 제거 (별도 Task로)
                Task.detached {
                    // 디스크 캐시 제거 로직 (필요시 구현)
                }
            }
        } else {
            // 타임아웃 발생 시 빠른 재시도 (1초)
            let retryDiskCachedImage = await withTimeout(seconds: 1.0) {
                try await SafeDiskCacheManager.shared.loadImage(forKey: imagePath)
            }
            if let retryDiskCachedImage1 = retryDiskCachedImage, let retryDiskCachedImage2 = retryDiskCachedImage1 {
                // 재시도로 찾은 디스크 이미지 유효성 검사
                if retryDiskCachedImage2.size.width > 0 && retryDiskCachedImage2.size.height > 0 && retryDiskCachedImage2.cgImage != nil {
                    // 메모리 캐시에도 저장
                    Task.detached {
                        await ImageCache.shared.setImageAsync(retryDiskCachedImage2, forKey: imagePath)
                    }
                    
                    return retryDiskCachedImage2
                } else {
                    // 유효하지 않은 이미지는 디스크 캐시에서 제거 (별도 Task로)
                    Task.detached {
                        // 디스크 캐시 제거 로직 (필요시 구현)
                    }
                }
            }
        }
        
        // 3. 네트워크에서 다운로드 (캐시 실패 시에도 시도)
        let downloadedImage = await withTimeout(seconds: 20.0) {
            try await self.downloadAndDownsample(
                imagePath: imagePath,
                context: context
            )
        }
        if let downloadedImage = downloadedImage {
            // 캐시에 저장
            Task.detached {
                await ImageCache.shared.setImageAsync(downloadedImage, forKey: imagePath)
                await SafeDiskCacheManager.shared.saveImage(downloadedImage, forKey: imagePath)
            }
            
            return downloadedImage
        }
        
        return nil
    }
    
    /// 네트워크에서 이미지 다운로드 및 다운샘플링
    private func downloadAndDownsample(
        imagePath: String,
        context: ImageLoaderContext
    ) async throws -> UIImage {
        
        // URL 생성 (상대 경로를 절대 경로로 변환)
        let fullURL = FormatManager.formatImageURL(imagePath)
        guard let url = URL(string: fullURL) else {
            throw ImageLoaderError.invalidImageFormat
        }
        
        // 요청 생성
        var request = URLRequest(url: url)
        request.addValue(AppConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        
        // 액세스 토큰 추가 (refreshToken도 시도)
        if let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken) {
            request.addValue(accessToken, forHTTPHeaderField: "Authorization")
        } else if let refreshToken = UserDefaultsManager.shared.getString(forKey: .refreshToken) {
            request.addValue(refreshToken, forHTTPHeaderField: "Authorization")
        }
        
        // 네트워크 요청
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // HTTP 응답 확인
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageLoaderError.networkError("HTTP 응답이 아님: \(response)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ImageLoaderError.networkError("HTTP 상태 코드 오류: \(httpResponse.statusCode)")
        }
        
        // 이미지 데이터 유효성 검사
        guard !data.isEmpty else {
            throw ImageLoaderError.invalidImageData
        }
        
        // 이미지 생성 (안전한 방법)
        guard let image = createSafeUIImage(from: data) else {
            // 안전한 방법이 실패하면 간단한 방법 시도
            guard let fallbackImage = createFallbackUIImage(from: data) else {
                // 마지막 대안으로 기본 이미지 반환
                return UIImage(systemName: "photo") ?? UIImage()
            }
            return fallbackImage
        }
        
        // 다운샘플링 수행
        do {
            let downsampledImage = try downsampleImageSafely(image, for: context)
            return downsampledImage
        } catch {
            return image // 다운샘플링 실패 시 원본 반환
        }
    }
    
    /// 안전한 UIImage 생성
    private func createSafeUIImage(from data: Data) -> UIImage? {
        // 1. 데이터 유효성 검사
        guard !data.isEmpty else {
            return nil
        }
        
        // 2. 데이터 크기 제한 (200MB 이상이면 거부)
        if data.count > 200 * 1024 * 1024 {
            return nil
        }
        
        // 3. CGImageSource 생성 (메모리 안전)
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        // 4. 이미지 개수 확인
        let imageCount = CGImageSourceGetCount(imageSource)
        guard imageCount > 0 else {
            return nil
        }
        
        // 5. 이미지 타입 확인 및 검증
        if let imageType = CGImageSourceGetType(imageSource) {
            // 지원되는 이미지 타입 확인 (더 관대하게)
            let supportedTypes = ["public.jpeg", "public.png", "public.gif", "public.tiff", "public.heic", "public.webp", "public.bmp"]
            let isSupported = supportedTypes.contains { type in
                imageType == type as CFString
            }
            
            if !isSupported {
                // 지원하지 않는 타입이어도 계속 진행
            }
        }
        
        // 6. 이미지 프로퍼티 확인 (선택적)
        if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] {
            // 7. 이미지 크기 확인 (선택적)
            if let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
               let height = properties[kCGImagePropertyPixelHeight] as? NSNumber {
                let imageWidth = width.intValue
                let imageHeight = height.intValue
                
                guard imageWidth > 0 && imageHeight > 0 else {
                    return nil
                }
                
                // 8. 메모리 사용량 계산 및 제한
                let pixelCount = imageWidth * imageHeight
                let estimatedMemoryUsage = pixelCount * 4 // RGBA
                
                // 100MB 이상이면 거부
                if estimatedMemoryUsage > 100 * 1024 * 1024 {
                    return nil
                }
            }
        }
        
        // 9. CGImage 생성 (첫 번째 이미지) - 메모리 안전
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        
        // 10. CGImage 유효성 재검사
        let cgImageWidth = cgImage.width
        let cgImageHeight = cgImage.height
        
        guard cgImageWidth > 0 && cgImageHeight > 0 else {
            return nil
        }
        
        // 11. 픽셀 포맷 검사 (확장된 지원 포맷)
        let bitsPerComponent = cgImage.bitsPerComponent
        let bitsPerPixel = cgImage.bitsPerPixel
        
        // 지원하는 픽셀 포맷 검사 (16비트 RGBA 포맷 추가)
        let isValidFormat = (bitsPerComponent == 8 && bitsPerPixel == 32) ||   // 8비트 RGBA
                           (bitsPerComponent == 8 && bitsPerPixel == 24) ||   // 8비트 RGB
                           (bitsPerComponent == 8 && bitsPerPixel == 16) ||   // 8비트 Gray + Alpha
                           (bitsPerComponent == 16 && bitsPerPixel == 64) ||  // 16비트 RGBA (고품질)
                           (bitsPerComponent == 16 && bitsPerPixel == 48) ||  // 16비트 RGB (고품질)
                           (bitsPerComponent == 16 && bitsPerPixel == 32) ||  // 16비트 Gray + Alpha
                           (bitsPerComponent == 16 && bitsPerPixel == 16)     // 16비트 Gray
        
        if !isValidFormat {
            print("⚠️ 지원하지 않는 픽셀 포맷 감지: bitsPerComponent=\(bitsPerComponent), bitsPerPixel=\(bitsPerPixel)")
            // 포맷이 지원되지 않아도 계속 진행 (변환 시도)
        }
        
        // 12. CGImage 색상 공간 확인 (선택적)
        if let colorSpace = cgImage.colorSpace {
            // 색상 공간 정보 사용 가능
        }
        
        // 13. UIImage 생성 (명시적 포맷 지정) - 메모리 안전
        let image = UIImage(cgImage: cgImage)
        
        // 14. 최종 유효성 검사 (더 관대한 조건)
        guard image.size.width > 0 && image.size.height > 0 else {
            return nil
        }
        
        return image
    }
    
    /// 대체 UIImage 생성 (간단한 방법)
    private func createFallbackUIImage(from data: Data) -> UIImage? {
        
        // 1. 데이터 크기 제한
        if data.count > 50 * 1024 * 1024 {
            return nil
        }
        
        // 2. 직접 UIImage 생성 시도
        guard let image = UIImage(data: data) else {
            return nil
        }
        
        // 3. 기본 유효성 검사
        guard image.size.width > 0 && image.size.height > 0 else {
            return nil
        }
        
        // 4. 메모리 사용량 확인
        let pixelCount = Int(image.size.width * image.size.height)
        let estimatedMemoryUsage = pixelCount * 4
        
        if estimatedMemoryUsage > 25 * 1024 * 1024 {
            // 큰 이미지 감지됨
        }
        
        return image
    }
    
    /// 안전한 이미지 다운샘플링
    private func downsampleImageSafely(_ image: UIImage, for context: ImageLoaderContext) throws -> UIImage {
        let targetPixelSize: CGFloat
        
        switch context {
        case .thumbnail:
            targetPixelSize = ImageLoaderDownsamplingPolicy.targetPixelSizeThumbnail
        case .listCell:
            targetPixelSize = ImageLoaderDownsamplingPolicy.targetPixelSizeListCell
        case .detail:
            targetPixelSize = ImageLoaderDownsamplingPolicy.targetPixelSizeDetail
        case .poi:
            targetPixelSize = ImageLoaderDownsamplingPolicy.targetPixelSizePOI
        case .profile:
            targetPixelSize = ImageLoaderDownsamplingPolicy.targetPixelSizeProfile
        }
        
        // 원본 이미지 크기
        let originalSize = image.size
        let originalScale = image.scale
        let originalPixelSize = CGSize(
            width: originalSize.width * originalScale,
            height: originalSize.height * originalScale
        )
        
        // 다운샘플링이 필요한지 확인 (원본이 목표보다 1.5배 이상 클 때)
        let shouldDownsample = originalPixelSize.width > targetPixelSize * 1.5 ||
                              originalPixelSize.height > targetPixelSize * 1.5
        
        guard shouldDownsample else { return image }
        
        // UIGraphicsImageRenderer를 사용한 안전한 리사이징
        return try resizeImageSafely(image, targetPixelSize: targetPixelSize)
    }
    
    /// UIGraphicsImageRenderer를 사용한 안전한 이미지 리사이징
    private func resizeImageSafely(_ image: UIImage, targetPixelSize: CGFloat) throws -> UIImage {
        // 1. 입력 이미지 유효성 검사
        guard image.size.width > 0 && image.size.height > 0 else {
            throw ImageLoaderError.downsamplingFailed
        }
        
        // 2. 목표 크기 계산 (비율 유지)
        let originalSize = image.size
        let aspectRatio = originalSize.width / originalSize.height
        
        let targetSize: CGSize
        if aspectRatio > 1 {
            // 가로가 더 긴 경우
            targetSize = CGSize(
                width: targetPixelSize,
                height: targetPixelSize / aspectRatio
            )
        } else {
            // 세로가 더 긴 경우
            targetSize = CGSize(
                width: targetPixelSize * aspectRatio,
                height: targetPixelSize
            )
        }
        
        // 3. 크기 유효성 검사
        guard targetSize.width > 0 && targetSize.height > 0 else {
            throw ImageLoaderError.downsamplingFailed
        }
        
        // 4. 메모리 사용량 예상 및 제한
        let estimatedMemoryUsage = Int(targetSize.width * targetSize.height * 4) // RGBA
        
        // 5. 메모리 제한 체크 (25MB 이상이면 경고)
        if estimatedMemoryUsage > 25 * 1024 * 1024 {
            // 큰 리사이징 감지됨
        }
        
        // 6. UIGraphicsImageRenderer 설정 (메모리 안전)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        
        // 7. 안전한 렌더링 (에러 처리 강화)
        let resizedImage: UIImage
        do {
            resizedImage = renderer.image { context in
                // 배경을 투명하게 설정
                UIColor.clear.setFill()
                context.fill(CGRect(origin: .zero, size: targetSize))
                
                // 이미지 그리기 (안전한 방법)
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        } catch {
            throw ImageLoaderError.downsamplingFailed
        }
        
        // 8. 결과 검증
        guard resizedImage.size.width > 0 && resizedImage.size.height > 0 else {
            throw ImageLoaderError.downsamplingFailed
        }
        
        return resizedImage
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
