
import Foundation

/*
 MARK: - 사용 예시 (FileDownloadRepository + Progress)
 
 // 1. Container에서 백그라운드 다운로드 사용
 class PostDetailContainer: ObservableObject {
     @Published var post: PostResponseEntity?
     @Published var downloadedFiles: [ServerFileEntity] = []
     @Published var downloadProgress: [String: Double] = [:]
     @Published var downloadStates: [String: FileDownloadProgress.DownloadState] = [:]
     @Published var isLoading = false
     
     private let fileDownloadRepository = FileDownloadRepositoryFactory.createWithAuth()
     private var cancellables = Set<AnyCancellable>()
     
     func loadPost(_ post: PostResponseEntity) {
         self.post = post
         
         // UI를 먼저 보여주고 백그라운드에서 파일 다운로드
         startBackgroundDownload(for: post.files)
     }
     
     private func startBackgroundDownload(for files: [ServerFileEntity]) {
         let serverPaths = files.map { $0.serverPath }
         
         // 이미 다운로드된 파일들 먼저 표시
         for file in files {
             if fileDownloadRepository.isFileDownloaded(serverPath: file.serverPath) {
                 if let downloadedFile = fileDownloadRepository.getDownloadedFile(serverPath: file.serverPath) {
                     downloadedFiles.append(downloadedFile)
                 }
             }
         }
         
         // 백그라운드에서 다운로드 시작
         fileDownloadRepository.downloadFilesInBackground(from: serverPaths)
             .receive(on: DispatchQueue.main)
             .sink { [weak self] progressMap in
                 self?.updateDownloadProgress(progressMap)
             }
             .store(in: &cancellables)
     }
     
     private func updateDownloadProgress(_ progressMap: [String: FileDownloadProgress]) {
         for (serverPath, progress) in progressMap {
             downloadProgress[serverPath] = progress.progress
             downloadStates[serverPath] = progress.state
             
             // 다운로드 완료된 파일 추가
             if progress.state == .downloaded, let downloadedFile = progress.downloadedFile {
                 if !downloadedFiles.contains(where: { $0.serverPath == serverPath }) {
                     downloadedFiles.append(downloadedFile)
                 }
             }
         }
     }
 }
 
 // 2. View에서 Progress 표시
 struct PostDetailView: View {
     @StateObject private var container = PostDetailContainer()
     
     var body: some View {
         VStack {
             // 포스트 내용 표시
             if let post = container.post {
                 Text(post.title)
                 Text(post.content)
                 
                 // 파일 목록 표시
                 LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                     ForEach(container.downloadedFiles, id: \.serverPath) { file in
                         FileThumbnailView(file: file)
                     }
                 }
                 
                 // 다운로드 진행률 표시
                 ForEach(Array(container.downloadProgress.keys), id: \.self) { serverPath in
                     if let progress = container.downloadProgress[serverPath],
                        let state = container.downloadStates[serverPath] {
                         ProgressView(value: progress)
                             .overlay(
                                 Text(state == .downloading ? "다운로드 중..." : 
                                      state == .downloaded ? "완료" : "대기 중")
                                     .font(.caption)
                             )
                     }
                 }
             }
         }
         .onAppear {
             // 포스트 데이터 로드 후 파일 다운로드 시작
             container.loadPost(postEntity)
         }
     }
 }
 
 // 3. 개별 파일 다운로드
 class SingleFileDownloadContainer: ObservableObject {
     @Published var downloadedFile: ServerFileEntity?
     @Published var progress: Double = 0.0
     @Published var state: FileDownloadProgress.DownloadState = .notStarted
     
     private let fileDownloadRepository = FileDownloadRepositoryFactory.createWithAuth()
     private var cancellables = Set<AnyCancellable>()
     
     func downloadFile(from serverPath: String) {
         fileDownloadRepository.downloadFileInBackground(from: serverPath)
             .receive(on: DispatchQueue.main)
             .sink { [weak self] progress in
                 self?.progress = progress.progress
                 self?.state = progress.state
                 
                 if progress.state == .downloaded {
                     self?.downloadedFile = progress.downloadedFile
                 }
             }
             .store(in: &cancellables)
     }
 }
 */

// MARK: - Post DTOs
struct PostRequestDTO: Codable {
    let category: String
    let title: String
    let content: String
    let longitude: Double
    let latitude: Double
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case category, title, content, longitude, latitude, files
    }
}

struct PostResponseDTO: Decodable {
    let postId: String?
    let category: String?
    let title: String?
    let content: String?
    let geolocation: GeolocationDTO?
    let creator: UserInfoResponseDTO?
    let files: [String?]?
    let isLike: Bool?
    let likeCount: Int?
    let comments: [CommentResponseDTO]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category, title, content, geolocation, creator, files, comments, createdAt, updatedAt
        case isLike = "is_like"
        case likeCount = "like_count"
    }
}

struct PostResponseEntity {
    let postId: String
    let category: String
    let title: String
    let content: String
    let geolocation: GeolocationEntity
    let creator: UserInfoEntity
    let files: [ServerFileEntity]  // 서버 파일 엔티티로 변경
    let comments: [CommentResponseEntity]
    let createdAt: String
    let updatedAt: String
}

extension PostResponseDTO {
    func toEntity() -> PostResponseEntity? {
        guard let postId = postId,
              let category = category,
              let title = title,
              let content = content,
              let geolocation = geolocation?.toEntity(),
              let creator = creator?.toEntity(),
              let createdAt = createdAt,
              let updatedAt = updatedAt else {
            return nil
        }
        
        // files 배열 처리 (nil 값 필터링하고 ServerFileEntity로 변환)
        let validFiles = files?.compactMap { $0 } ?? []
        let serverFileEntities = validFiles.map { ServerFileEntity(serverPath: $0) }
        
        // comments 배열 처리 (nil 값 필터링)
        let validComments = comments?.compactMap { $0.toEntity() } ?? []
        
        return PostResponseEntity(
            postId: postId,
            category: category,
            title: title,
            content: content,
            geolocation: geolocation,
            creator: creator,
            files: serverFileEntities,
            comments: validComments,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}