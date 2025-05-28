//
//  DownSampler.swift
//  Anlaka
//
//  Created by 최정안 on 5/27/25.
//

import UIKit
import ImageIO
import CoreGraphics

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
        let pixelSize = CGSize(width: pointSize.width * scale, height: pointSize.height * scale)
        
        // 데이터 크기 및 시작 부분 로깅
        //print("📥 받은 데이터 크기: \(imageData.count) bytes")
        let firstBytes = imageData.prefix(4).map({ String(format: "%02x", $0) }).joined()
        //print("📝 데이터 시작 바이트: \(firstBytes)")
        
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            print("❌ 데이터로부터 이미지 소스 생성 실패")
            if let textContent = String(data: imageData, encoding: .utf8) {
                print("📝 받은 데이터 내용(텍스트): \(textContent)")
            }
            return nil
        }
        
        return await downsampleImageSource(imageSource, to: pixelSize, scale: scale)
    }
    
    /// 이미지 소스로부터 비동기 다운샘플링 수행
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
                        continuation.resume(returning: UIImage(cgImage: cgImage))
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
                    continuation.resume(returning: UIImage(cgImage: resizedImage))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// 이미지 다운로드 및 다운샘플링
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
        guard let url = URL(string: FormatManager.formatImageURL(imagePath)) else {
            print("❌ 잘못된 URL 형식: \(imagePath)")
            return nil
        }
        
        //print("🌐 이미지 다운로드 시작: \(url)")
        
        var request = URLRequest(url: url)
        request.addValue(Environment.apiKey, forHTTPHeaderField: "SeSACKey")
        if let accessToken = UserDefaultsManager.shared.getString(forKey: .refreshToken) {
            request.addValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                //print("📡 서버 응답 코드: \(httpResponse.statusCode)")
                //print("📝 응답 헤더: \(httpResponse.allHeaderFields)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ HTTP 에러: \(httpResponse.statusCode)")
                    return nil
                }
            }
            
            //print("📥 데이터 수신 완료: \(data.count) bytes")
            
            let downsampledImage = await downsampleImage(from: data, to: pointSize, scale: scale)
            if downsampledImage == nil {
                print("❌ 다운샘플링 실패")
            } else {
                //print("✅ 다운샘플링 성공")
            }
            return downsampledImage
            
        } catch {
            print("❌ 네트워크 에러: \(error.localizedDescription)")
            return nil
        }
    }
}
