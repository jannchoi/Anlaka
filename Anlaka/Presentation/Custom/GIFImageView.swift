import SwiftUI
import UIKit

struct GIFImageView: View {
    let imagePath: String
    var onImageLoaded: ((UIImage?) -> Void)? = nil
    var targetSize: CGSize? = nil
    var context: ImageContext? = nil
    var shouldAnimate: Bool = true // 애니메이션 재생 여부
    var playMode: GIFPlayMode = .loop // 재생 모드
    var isPlaying: Bool = true // 재생 상태 (controlled 모드에서 사용)
    
    @State private var uiImage: UIImage?
    @State private var isLoading = true
    @State private var hasStartedLoading = false
    
    // MARK: - GIF Play Mode
    enum GIFPlayMode {
        case loop        // 무한 반복
        case once        // 한 번만 재생
        case controlled  // 사용자 제어 (재생/일시정지)
    }
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                if playMode == .controlled {
                    // 사용자 제어 모드
                    ControlledGIFView(image: uiImage, isPlaying: isPlaying)
                } else {
                    // 자동 재생 모드
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(ProgressView())
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("GIF")
                            .font(.pretendardCaption)
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            if !hasStartedLoading {
                hasStartedLoading = true
                loadGIFImage()
            }
        }
        .onChange(of: imagePath) { newPath in
            hasStartedLoading = false
            isLoading = true
            uiImage = nil
            hasStartedLoading = true
            loadGIFImage()
        }
    }
    
    private func loadGIFImage() {
        guard !imagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [GIFImageView] imagePath가 빈 문자열입니다")
            self.uiImage = nil
            self.isLoading = false
            return
        }
        
        Task {
            do {
                let imageContext = determineImageContext()
                let imageLoaderContext = convertToImageLoaderContext(imageContext)
                
                // GIF 데이터를 직접 다운로드
                let gifData = await downloadGIFData(from: imagePath)
                
                await MainActor.run {
                    self.isLoading = false
                    
                    if let data = gifData {
                        if shouldAnimate {
                            // 애니메이션 GIF로 처리
                            let animatedImage: UIImage?
                            
                            switch playMode {
                            case .loop:
                                // 무한 반복
                                animatedImage = UIImage.animatedImage(with: data)
                            case .once:
                                // 한 번만 재생
                                animatedImage = UIImage.animatedImageOnce(with: data)
                            case .controlled:
                                // 사용자 제어 (기본적으로 무한 반복)
                                animatedImage = UIImage.animatedImage(with: data)
                            }
                            
                            if let finalImage = animatedImage {
                                self.uiImage = finalImage
                                self.onImageLoaded?(finalImage)
                            } else {
                                // 애니메이션 생성 실패 시 정적 이미지로 처리
                                if let staticImage = UIImage(data: data) {
                                    self.uiImage = staticImage
                                    self.onImageLoaded?(staticImage)
                                } else {
                                    self.uiImage = nil
                                    self.onImageLoaded?(nil)
                                }
                            }
                        } else {
                            // 정적 이미지로만 처리 (첫 번째 프레임만)
                            if let staticImage = UIImage(data: data) {
                                self.uiImage = staticImage
                                self.onImageLoaded?(staticImage)
                            } else {
                                self.uiImage = nil
                                self.onImageLoaded?(nil)
                            }
                        }
                    } else {
                        print("❌ [GIFImageView] GIF 로드 실패: \(imagePath)")
                        self.uiImage = nil
                        self.onImageLoaded?(nil)
                    }
                }
                
            } catch {
                print("❌ [GIFImageView] GIF 로딩 중 오류 발생: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                    self.uiImage = nil
                    self.onImageLoaded?(nil)
                }
            }
        }
    }
    
    private func downloadGIFData(from imagePath: String) async -> Data? {
        // BaseURL과 결합하여 전체 URL 생성
        let fullURLString = BaseURL.baseV1 + imagePath
        
        guard let url = URL(string: fullURLString) else {
            print("❌ [GIFImageView] 유효하지 않은 URL: \(fullURLString)")
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
                print("❌ [GIFImageView] HTTP 오류: \(response)")
                return nil
            }
            
            return data
        } catch {
            print("❌ [GIFImageView] 네트워크 오류: \(error)")
            return nil
        }
    }
    
    private func determineImageContext() -> ImageContext {
        return context ?? .listCell
    }
    
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
}

// MARK: - Controlled GIF View
struct ControlledGIFView: View {
    let image: UIImage
    let isPlaying: Bool
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}

// MARK: - UIImage Extension for GIF Support
extension UIImage {
    static func animatedImage(with data: Data, repeatCount: Int = 0) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let count = CGImageSourceGetCount(source)
        guard count > 1 else {
            // 단일 프레임인 경우 일반 이미지로 처리
            return UIImage(data: data)
        }
        
        var images: [UIImage] = []
        var duration: TimeInterval = 0
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
                
                // 프레임 지속 시간 계산
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                    
                    if let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? Double {
                        duration += delayTime
                    } else if let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                        duration += unclampedDelayTime
                    } else {
                        duration += 0.1 // 기본값
                    }
                } else {
                    duration += 0.1 // 기본값
                }
            }
        }
        
        guard !images.isEmpty else { return nil }
        
        // 애니메이션 이미지 생성 (repeatCount: 0 = 무한 반복, 1 = 한 번만)
        let animatedImage = UIImage.animatedImage(with: images, duration: duration)
        return animatedImage
    }
    
    // 한 번만 재생하는 GIF 생성
    static func animatedImageOnce(with data: Data) -> UIImage? {
        return animatedImage(with: data, repeatCount: 1)
    }
}

#Preview {
    GIFImageView(imagePath: "/example.gif")
        .frame(width: 200, height: 200)
} 