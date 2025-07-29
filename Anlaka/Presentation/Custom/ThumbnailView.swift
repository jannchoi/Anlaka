import SwiftUI

struct ThumbnailView: View {
    let fileURL: String
    let fileType: ThumbnailExtractor.FileType
    let size: CGSize
    let cornerRadius: CGFloat
    
    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    @State private var hasStartedLoading = false
    
    init(fileURL: String, size: CGSize = CGSize(width: 80, height: 80), cornerRadius: CGFloat = 6) {
        self.fileURL = fileURL
        self.fileType = ThumbnailExtractor.getFileType(from: fileURL)
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                // 실제 썸네일 표시
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(cornerRadius)
                    .overlay(
                        // 파일 타입별 오버레이
                        fileTypeOverlay
                    )
            } else if isLoading {
                // 로딩 상태
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            } else {
                // 로드 실패 시 기본 아이콘
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        fileTypeOverlay
                    )
            }
        }
        .onAppear {
            if !hasStartedLoading {
                hasStartedLoading = true
                loadThumbnail()
            }
        }
        .onChange(of: fileURL) { newURL in
            hasStartedLoading = false
            isLoading = true
            thumbnail = nil
            if !newURL.isEmpty {
                hasStartedLoading = true
                loadThumbnail()
            }
        }
    }
    
    // MARK: - 파일 타입별 오버레이
    @ViewBuilder
    private var fileTypeOverlay: some View {
        switch fileType {
        case .video:
            VStack(spacing: 4) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                
                Text(getFileExtension().uppercased())
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(3)
            }
            
        case .gif:
            VStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                
                Text("GIF")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(3)
            }
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - 썸네일 로드
    private func loadThumbnail() {
        Task {
            let extractedThumbnail = await ThumbnailExtractor.shared.extractThumbnailFromURL(fileURL, fileType: fileType)
            
            await MainActor.run {
                self.isLoading = false
                if let thumbnail = extractedThumbnail {
                    self.thumbnail = thumbnail
                } else {
                    print("⚠️ [ThumbnailView] 썸네일 로드 실패, 기본 아이콘 표시: \(fileURL)")
                    // 썸네일이 nil이면 기본 아이콘이 표시됨
                }
            }
        }
    }
    
    // MARK: - 파일 확장자 추출
    private func getFileExtension() -> String {
        return URL(string: fileURL)?.pathExtension.lowercased() ?? ""
    }
}

#Preview {
    VStack(spacing: 20) {
        ThumbnailView(fileURL: "/example.mp4", size: CGSize(width: 100, height: 100))
        ThumbnailView(fileURL: "/example.gif", size: CGSize(width: 100, height: 100))
    }
    .padding()
} 
