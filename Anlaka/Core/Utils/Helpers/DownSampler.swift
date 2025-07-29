//
//  DownSampler.swift
//  Anlaka
//
//  Created by 최정안 on 5/27/25.
//

import UIKit
import ImageIO
import CoreGraphics

// MARK: - 다운샘플링 정책 핵심 상수
struct DownsamplingPolicy {
    // ✅ 핵심 상수 정의
    static let targetPixelSizeThumbnail: CGFloat = 332  // 166pt × 2x scale
    static let targetPixelSizeListCell: CGFloat = 300   // 150pt × 2x scale
    static let targetPixelSizeDetail: CGFloat = 750     // 375pt × 2x scale
    static let downsamplingScaleFactor: CGFloat = 1.5   // 다운샘플링 비율
    static let maxImageLoadSize: Int = 5 * 1024 * 1024 // 5MB
    static let deviceScreenScale: CGFloat = UIScreen.main.scale // 2.0 or 3.0
    static let allowDownsampleBelowScale: Bool = true
    
    // 컨텍스트별 타겟 크기
    static let targetPixelSizePOI: CGFloat = 80         // 40pt × 2x scale
    static let targetPixelSizeProfile: CGFloat = 96     // 48pt × 2x scale
}

// MARK: - 이미지 컨텍스트 열거형
enum ImageContext: String, CaseIterable {
    case thumbnail = "thumbnail"
    case listCell = "listCell"
    case detail = "detail"
    case poi = "poi"
    case profile = "profile"
}

// MARK: - 다운샘플링 이미지 로더
class DownsamplingImageLoader {
    static let shared = DownsamplingImageLoader()
    
    private init() {}
    
    // ✅ 이미지 다운샘플링 요청 진입점
    func loadImage(url: URL, context: ImageContext) async -> UIImage? {
        let targetSize = determineTargetPixelSize(context)
        
        // 1. 네트워크에서 이미지 다운로드
        guard let imageData = await downloadImage(url) else {
            print("❌ 이미지 다운로드 실패: \(url)")
            return nil
        }
        
        // 2. 이미지 데이터 유효성 검사
        guard ImageValidationHelper.validateImageData(imageData) else {
            print("❌ 다운로드된 이미지 데이터가 유효하지 않음: \(url)")
            return nil
        }
        
        // 3. 용량 체크 및 압축
        let processedData = await compressIfNeeded(imageData)
        
        // 4. 이미지 디코딩
        guard let image = UIImage(data: processedData) else {
            print("❌ 이미지 디코딩 실패: \(url)")
            return nil
        }
        
        // 5. 이미지 유효성 검사
        guard ImageValidationHelper.validateUIImage(image) else {
            print("❌ 디코딩된 이미지가 유효하지 않음: \(url)")
            return nil
        }
        
        // 6. 안전한 포맷으로 변환 (C++ 모듈 호환성)
        guard let safeImage = ImageValidationHelper.convertToSafeFormat(image) else {
            print("❌ 안전한 포맷으로 변환 실패: \(url)")
            return nil
        }
        
        // 7. 다운샘플링 필요 여부 판단 및 수행
        let finalImage = await downsampleIfNeeded(safeImage, targetSize: targetSize)
        
        return finalImage
    }
    
    // ✅ 컨텍스트에 따라 타겟 픽셀 사이즈 반환
    private func determineTargetPixelSize(_ context: ImageContext) -> CGFloat {
        switch context {
        case .thumbnail:
            return DownsamplingPolicy.targetPixelSizeThumbnail
        case .listCell:
            return DownsamplingPolicy.targetPixelSizeListCell
        case .detail:
            return DownsamplingPolicy.targetPixelSizeDetail
        case .poi:
            return DownsamplingPolicy.targetPixelSizePOI
        case .profile:
            return DownsamplingPolicy.targetPixelSizeProfile
        }
    }
    
    // ✅ 다운샘플링 조건 판단
    private func shouldDownsample(_ image: UIImage, targetSize: CGFloat) -> Bool {
        let originalSize = max(image.size.width * image.scale, image.size.height * image.scale)
        return (originalSize / targetSize) >= DownsamplingPolicy.downsamplingScaleFactor
    }
    
    // ✅ 다운샘플링 수행 (안전한 포맷 보장)
    private func downsampleIfNeeded(_ image: UIImage, targetSize: CGFloat) async -> UIImage {
        // 다운샘플링이 필요하지 않으면 원본 반환 (이미 안전한 포맷)
        guard shouldDownsample(image, targetSize: targetSize) else {
            return image
        }
        
        // Retina 디바이스에서 다운샘플링 제한 확인
        var finalTargetSize = targetSize
        if !DownsamplingPolicy.allowDownsampleBelowScale && 
           DownsamplingPolicy.deviceScreenScale == 3.0 {
            finalTargetSize = targetSize * DownsamplingPolicy.deviceScreenScale
        }
        
        return await performDownsampling(image, to: finalTargetSize)
    }
    
    // ✅ 실제 다운샘플링 수행 (안전한 포맷 보장)
    private func performDownsampling(_ image: UIImage, to targetSize: CGFloat) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let cgImage = image.cgImage else {
                    continuation.resume(returning: image)
                    return
                }
                
                // 이미지 유효성 재검사
                guard ImageValidationHelper.validateUIImage(image) else {
                    print("❌ 다운샘플링 전 이미지 유효성 검사 실패")
                    continuation.resume(returning: image)
                    return
                }
                
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceShouldCacheImmediately: false,
                    kCGImageSourceThumbnailMaxPixelSize: targetSize
                ]
                
                guard let imageData = image.jpegData(compressionQuality: 1.0),
                      let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
                      let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                    continuation.resume(returning: image)
                    return
                }
                
                // 안전한 포맷으로 최종 변환
                let result = UIImage(cgImage: thumbnail, scale: DownsamplingPolicy.deviceScreenScale, orientation: image.imageOrientation)
                
                // 최종 유효성 검사
                guard ImageValidationHelper.validateUIImage(result) else {
                    print("❌ 다운샘플링 후 이미지 유효성 검사 실패")
                    continuation.resume(returning: image)
                    return
                }
                
                continuation.resume(returning: result)
            }
        }
    }
    
    // ✅ 이미지 압축 (용량 제한 대응) - 안전한 포맷 보장
    private func compressIfNeeded(_ imageData: Data) async -> Data {
        guard imageData.count > DownsamplingPolicy.maxImageLoadSize else {
            return imageData
        }
        
        guard let image = UIImage(data: imageData) else {
            return imageData
        }
        
        // 이미지 유효성 검사
        guard ImageValidationHelper.validateUIImage(image) else {
            print("❌ 압축 전 이미지 유효성 검사 실패")
            return imageData
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var compressionQuality: CGFloat = 0.5
                var compressedData = imageData
                
                while compressionQuality > 0.1 {
                    if let jpegData = image.jpegData(compressionQuality: compressionQuality),
                       jpegData.count <= DownsamplingPolicy.maxImageLoadSize {
                        compressedData = jpegData
                        break
                    }
                    compressionQuality -= 0.1
                }
                
                continuation.resume(returning: compressedData)
            }
        }
    }
    
    // ✅ 네트워크 이미지 다운로드
    private func downloadImage(_ url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.addValue(AppConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        if let accessToken = KeychainManager.shared.getString(forKey: .accessToken) {
            request.addValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ HTTP 에러: \(httpResponse.statusCode)")
                    return nil
                }
            }
            
            return data
        } catch {
            print("❌ 네트워크 에러: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - 기존 ImageDownsampler 클래스 (하위 호환성 유지)
class ImageDownsampler {
    
    /// 이미지를 지정된 크기로 비동기 다운샘플링
    /// - Parameters:
    ///   - imageURL: 이미지 파일 URL
    ///   - pointSize: 목표 크기 (포인트 단위)
    ///   - scale: 화면 스케일 (기본값: 현재 화면 스케일)
    /// - Returns: 다운샘플링된 UIImage
    static func downsampleImage(at imageURL: URL, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) async -> UIImage? {
        // 픽셀 크기 계산
        let pixelSize = CGSize(width: pointSize.width * scale, height: pointSize.height * scale)
        
        // 이미지 소스 생성
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil) else {
            print("❌ 이미지 소스 생성 실패: \(imageURL)")
            return nil
        }
        
        return await downsampleImageSource(imageSource, to: pixelSize, scale: scale)
    }
    
    /// Data로부터 이미지 비동기 다운샘플링
    /// - Parameters:
    ///   - imageData: 이미지 데이터
    ///   - pointSize: 목표 크기 (포인트 단위)
    ///   - scale: 화면 스케일
    /// - Returns: 다운샘플링된 UIImage
    static func downsampleImage(from imageData: Data, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) async -> UIImage? {
        // 이미지 데이터 유효성 검사
        guard ImageValidationHelper.validateImageData(imageData) else {
            print("❌ 입력 이미지 데이터가 유효하지 않음")
            return nil
        }
        
        let pixelSize = CGSize(width: pointSize.width * scale, height: pointSize.height * scale)
        
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            print("❌ 데이터로부터 이미지 소스 생성 실패")
            return nil
        }
        
        return await downsampleImageSource(imageSource, to: pixelSize, scale: scale)
    }
    
    /// 이미지 소스로부터 비동기 다운샘플링 수행 (안전한 포맷 보장)
    private static func downsampleImageSource(_ imageSource: CGImageSource, to pixelSize: CGSize, scale: CGFloat) async -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(pixelSize.width, pixelSize.height)
        ]

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                    print("❌ 썸네일 생성 실패")
                    continuation.resume(returning: nil)
                    return
                }

                let width = Int(pixelSize.width)
                let height = Int(pixelSize.height)

                // 안전한 CGContext 생성 (C++ 모듈 호환성 보장)
                guard let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ) else {
                    print("❌ CGContext 생성 실패")
                    continuation.resume(returning: nil)
                    return
                }

                context.interpolationQuality = .high
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

                guard let finalImage = context.makeImage() else {
                    print("❌ CGContext에서 최종 이미지 생성 실패")
                    continuation.resume(returning: nil)
                    return
                }

                let result = UIImage(cgImage: finalImage, scale: scale, orientation: .up)
                
                // 최종 유효성 검사
                guard ImageValidationHelper.validateUIImage(result) else {
                    print("❌ 다운샘플링 결과 이미지 유효성 검사 실패")
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: result)
            }
        }
    }

    /// 메모리 효율적인 이미지 비동기 리사이징 (큰 이미지용)
    /// - Parameters:
    ///   - imageURL: 이미지 파일 URL
    ///   - maxPixelSize: 최대 픽셀 크기
    /// - Returns: 리사이징된 UIImage
    static func efficientImageResize(imageURL: URL, maxPixelSize: CGFloat) async -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil) else {
            return nil
        }
        
        // 이미지 프로퍼티 확인
        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? NSNumber,
              let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? NSNumber else {
            return nil
        }
        
        let originalWidth = CGFloat(pixelWidth.doubleValue)
        let originalHeight = CGFloat(pixelHeight.doubleValue)
        let maxDimension = max(originalWidth, originalHeight)
        
        // 이미 작은 이미지면 원본 반환
        if maxDimension <= maxPixelSize {
            return await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    if let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
                        let image = UIImage(cgImage: cgImage)
                        
                        // 유효성 검사 및 안전한 포맷 변환
                        guard ImageValidationHelper.validateUIImage(image),
                              let safeImage = ImageValidationHelper.convertToSafeFormat(image) else {
                            continuation.resume(returning: nil)
                            return
                        }
                        
                        continuation.resume(returning: safeImage)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
        
        // 다운샘플링 수행
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if let resizedImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
                    let image = UIImage(cgImage: resizedImage)
                    
                    // 유효성 검사 및 안전한 포맷 변환
                    guard ImageValidationHelper.validateUIImage(image),
                          let safeImage = ImageValidationHelper.convertToSafeFormat(image) else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    continuation.resume(returning: safeImage)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// 이미지 다운로드 및 다운샘플링 (새로운 컨텍스트 기반 API)
    /// - Parameters:
    ///   - imagePath: 이미지 경로 (예: "/data/estates/xxx.png")
    ///   - context: 이미지 사용 컨텍스트
    /// - Returns: 다운샘플링된 UIImage
    static func downloadAndDownsample(
        imagePath: String,
        context: ImageContext
    ) async -> UIImage? {
        guard !imagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [DownSampler] imagePath가 빈 문자열입니다")
            return nil
        }
        
        guard let url = URL(string: BaseURL.baseV1 + imagePath) else {
            print("❌ 잘못된 URL 형식: \(imagePath)")
            return nil
        }
        
        return await DownsamplingImageLoader.shared.loadImage(url: url, context: context)
    }
    
    /// 이미지 다운로드 및 다운샘플링 (기존 API - 하위 호환성)
    /// - Parameters:
    ///   - imagePath: 이미지 경로 (예: "/data/estates/xxx.png")
    ///   - pointSize: 목표 크기 (포인트 단위)
    ///   - scale: 화면 스케일 (기본값: 현재 화면 스케일)
    /// - Returns: 다운샘플링된 UIImage
    static func downloadAndDownsample(
        imagePath: String,
        to pointSize: CGSize,
        scale: CGFloat = UIScreen.main.scale
    ) async -> UIImage? {
        guard !imagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [DownSampler] imagePath가 빈 문자열입니다")
            return nil
        }
        
        guard let url = URL(string: BaseURL.baseV1 + imagePath) else {
            print("❌ 잘못된 URL 형식: \(imagePath)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.addValue(AppConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        if let accessToken = KeychainManager.shared.getString(forKey: .accessToken) {
            request.addValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ HTTP 에러: \(httpResponse.statusCode)")
                    return nil
                }
            }
            
            // 이미지 데이터 유효성 검사
            guard ImageValidationHelper.validateImageData(data) else {
                print("❌ 다운로드된 이미지 데이터가 유효하지 않음: \(imagePath)")
                return nil
            }
            
            let downsampledImage = await downsampleImage(from: data, to: pointSize, scale: scale)
            if downsampledImage == nil {
                print("❌ 다운샘플링 실패: \(imagePath)")
            }
            return downsampledImage
            
        } catch {
            print("❌ 네트워크 에러: \(error.localizedDescription)")
            return nil
        }
    }
}
