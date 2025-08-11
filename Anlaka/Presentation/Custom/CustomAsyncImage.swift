
// MARK: - 안전한 캐싱 로직

//
//  CustomAsyncImage.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI

struct CustomAsyncImage: View {
    let imagePath: String?  // 예: "/data/estates/xxx.png"
    var onImageLoaded: ((UIImage?) -> Void)? = nil // 이미지 로드 완료 콜백
    var targetSize: CGSize? = nil // 다운샘플링할 목표 크기
    var context: ImageContext? = nil // 이미지 사용 컨텍스트
    
    @State private var uiImage: UIImage?
    @State private var isLoading = true
    @State private var hasStartedLoading = false // 중복 로딩 방지
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(ProgressView())
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("이미지")
                    .font(.pretendardCaption)
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            if !hasStartedLoading {
                hasStartedLoading = true
                loadImage()
            }
        }
        .onChange(of: imagePath) { newPath in
            // 이미지 경로가 변경되면 다시 로딩
            hasStartedLoading = false
            isLoading = true
            uiImage = nil
            if let path = newPath {
                hasStartedLoading = true
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        guard let imagePath = imagePath, !imagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [CustomAsyncImage] imagePath가 nil이거나 빈 문자열입니다")
            self.uiImage = nil
            self.isLoading = false
            return
        }
        
        
        
        Task {
            do {
                // ImageLoader를 직접 사용하여 일관된 로딩 처리
                let imageContext = determineImageContext()
                let imageLoaderContext = convertToImageLoaderContext(imageContext)
                
                
                
                let loadedImage = await ImageLoader.shared.loadImage(
                    from: imagePath,
                    context: imageLoaderContext,
                    targetSize: targetSize
                )
                
                await MainActor.run {
                    self.isLoading = false
                    
                    if let image = loadedImage {
                        
                        self.uiImage = image
                        self.onImageLoaded?(image)
                    } else {
                        print("❌ [CustomAsyncImage] 이미지 로드 실패: \(imagePath)")
                        self.uiImage = nil
                        self.onImageLoaded?(nil)
                    }
                }
                
            } catch {
                print("❌ [CustomAsyncImage] 이미지 로딩 중 오류 발생: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                    self.uiImage = nil
                    self.onImageLoaded?(nil)
                }
            }
        }
    }
    
    private func downloadImage(from imagePath: String) async {
        // 이 메서드는 더 이상 사용하지 않음 - ImageLoader로 대체됨
        print("⚠️ [CustomAsyncImage] downloadImage 메서드는 더 이상 사용되지 않습니다.")
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async -> T? {
        do {
            return try await withThrowingTaskGroup(of: T?.self) { group in
                group.addTask {
                    do {
                        return try await operation()
                    } catch {
                        print("❌ 작업 실행 중 오류: \(error.localizedDescription)")
                        return nil
                    }
                }
                
                group.addTask {
                    do {
                        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                    } catch {
                        // 에러 무시
                    }
                    return nil
                }
                
                for try await result in group {
                    if let result = result {
                        group.cancelAll() // 타임아웃 처리시 다른 태스크 취소
                        return result
                    }
                }
                
                return nil
            }
        } catch {
            print("❌ 타임아웃 작업 중 오류: \(error.localizedDescription)")
            return nil
        }
    }
    
    // ✅ 컨텍스트 결정 로직
    private func determineImageContext() -> ImageContext {
        // 명시적으로 지정된 컨텍스트가 있으면 사용
        if let context = context {
            return context
        }
        
        // targetSize를 기반으로 컨텍스트 추정
        guard let targetSize = targetSize else {
            return .listCell // 기본값
        }
        
        let maxDimension = max(targetSize.width, targetSize.height)
        let pixelDimension = maxDimension * UIScreen.main.scale
        
        // 컨텍스트별 크기 기준으로 판단
        if pixelDimension <= DownsamplingPolicy.targetPixelSizePOI {
            return .poi
        } else if pixelDimension <= DownsamplingPolicy.targetPixelSizeProfile {
            return .profile
        } else if pixelDimension <= DownsamplingPolicy.targetPixelSizeThumbnail {
            return .thumbnail
        } else if pixelDimension <= DownsamplingPolicy.targetPixelSizeListCell {
            return .listCell
        } else {
            return .detail
        }
    }
    
    // ✅ ImageContext를 ImageLoaderContext로 변환
    private func convertToImageLoaderContext(_ context: ImageContext) -> ImageLoaderContext {
        switch context {
        case .thumbnail:
            return .thumbnail
        case .listCell:
            return .listCell
        case .detail:
            return .detail
        case .poi:
            return .poi
        case .profile:
            return .profile
        }
    }
    
    // 기존 다운샘플링 로직 (하위 호환성)
    private func downsampleIfNeeded(_ image: UIImage) -> UIImage {
        guard let targetSize = targetSize else { return image }
        
        // 원본 이미지 크기
        let originalSize = image.size
        let originalScale = image.scale
        let originalPixelSize = CGSize(
            width: originalSize.width * originalScale,
            height: originalSize.height * originalScale
        )
        
        // 목표 픽셀 크기
        let targetPixelSize = CGSize(
            width: targetSize.width * UIScreen.main.scale,
            height: targetSize.height * UIScreen.main.scale
        )
        
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
}

// MARK: - 프리로딩 기능을 위한 확장
extension CustomAsyncImage {
    /// 이미지 프리로딩 (스크롤 성능 향상을 위해)
    static func preloadImages(_ imagePaths: [String]) {
        let preloadLimit = ImageCachePolicy.preloadLimit
        
        // 프리로딩 제한을 적용하여 과도한 네트워크 요청 방지
        let limitedPaths = Array(imagePaths.prefix(preloadLimit))
        
        for path in limitedPaths {
            // 빈 경로 체크
            guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("⚠️ [CustomAsyncImage] 프리로딩할 path가 빈 문자열입니다")
                continue
            }
            
            // 메모리 캐시에 없고 디스크 캐시에도 없는 경우에만 프리로딩
            if ImageCache.shared.image(forKey: path) == nil &&
               DiskCacheManager.shared.loadImage(forKey: path) == nil {
                
                preloadImage(path)
            }
        }
    }
    
    private static func preloadImage(_ imagePath: String) {
        guard !imagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [CustomAsyncImage] 프리로딩할 imagePath가 빈 문자열입니다")
            return
        }
        
        guard let url = URL(string: FormatManager.formatImageURL(imagePath)) else { return }
        
        var request = URLRequest(url: url)
        request.addValue(AppConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        if let accessToken = KeychainManager.shared.getString(forKey: .accessToken) {
            request.addValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                // 프리로딩된 이미지를 캐시에 저장
                ImageCache.shared.setImage(image, forKey: imagePath)
                DiskCacheManager.shared.saveImage(image, forKey: imagePath)
            }
        }.resume()
    }
}

// MARK: - 컨텍스트별 편의 이니셜라이저
extension CustomAsyncImage {
    /// 썸네일용 이미지 뷰
    static func thumbnail(imagePath: String?, onImageLoaded: ((UIImage?) -> Void)? = nil) -> CustomAsyncImage {
        CustomAsyncImage(
            imagePath: imagePath,
            onImageLoaded: onImageLoaded,
            context: .thumbnail
        )
    }
    
    /// 리스트 셀용 이미지 뷰
    static func listCell(imagePath: String?, onImageLoaded: ((UIImage?) -> Void)? = nil) -> CustomAsyncImage {
        CustomAsyncImage(
            imagePath: imagePath,
            onImageLoaded: onImageLoaded,
            context: .listCell
        )
    }
    
    /// 상세 페이지용 이미지 뷰
    static func detail(imagePath: String?, onImageLoaded: ((UIImage?) -> Void)? = nil) -> CustomAsyncImage {
        CustomAsyncImage(
            imagePath: imagePath,
            onImageLoaded: onImageLoaded,
            context: .detail
        )
    }
    
    /// POI용 이미지 뷰
    static func poi(imagePath: String?, onImageLoaded: ((UIImage?) -> Void)? = nil) -> CustomAsyncImage {
        CustomAsyncImage(
            imagePath: imagePath,
            onImageLoaded: onImageLoaded,
            context: .poi
        )
    }
    
    /// 프로필용 이미지 뷰
    static func profile(imagePath: String?, onImageLoaded: ((UIImage?) -> Void)? = nil) -> CustomAsyncImage {
        CustomAsyncImage(
            imagePath: imagePath,
            onImageLoaded: onImageLoaded,
            context: .profile
        )
    }
}
