import Foundation
import CoreLocation
import CryptoKit // SHA256 해시 계산을 위해 추가

struct PostingModel {
    var postId: String
    var post: PostResponseEntity?
    var isEditMode: Bool = false
    var toast: FancyToast? = nil
    var showErrorAlert: Bool = false
    var errorMessage: String = ""
    var onRetry: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    
    // 파일 검증 결과
    var validFiles: [SelectedFile] = []
    var invalidFileIndices: Set<Int> = []
    var invalidFileReasons: [Int: String] = [:]
    var hasDuplicateFile: Bool = false
    
    // 수정 모드에서 기존 파일 관리
    var existingFiles: [String] = [] // 서버에 업로드된 기존 파일들
    var deletedFiles: [String] = [] // 삭제된 기존 파일들
    
    // 위치 권한 관련
    var hasLocationPermission: Bool = false
    var locationPermissionDenied: Bool = false
}

enum PostingIntent {
    case initialRequest
    case editPost(postId: String, posting: EditPostRequestDTO)
    case deletePost(postId: String)
    case savePost(posting: PostRequestDTO)
    case savePostWithData(title: String, content: String, category: String, selectedFiles: [SelectedFile])
    case validateFiles(files: [SelectedFile])
    case deleteExistingFile(String) // 기존 파일 삭제
    case checkLocationPermission
    case retry
    case dismiss
}

@MainActor
class PostingContainer: ObservableObject, LocationServiceDelegate {
    @Published var model: PostingModel = PostingModel(postId: "")
    @Published var isSaving: Bool = false
    @Published var currentAddress: String = ""
    private let postingUseCase: PostingUseCase
    private let locationService: LocationService // DI로 받음
    
    // 신규 작성/수정 통합 초기화
    init(post: PostResponseEntity? = nil, postingUseCase: PostingUseCase, locationService: LocationService) {
        if let post = post {
            self.model = PostingModel(
                postId: post.postId,
                post: post,
                isEditMode: true,
                existingFiles: post.files.map{$0.serverPath}
            )
        } else {
            self.model = PostingModel(postId: UUID().uuidString, post: nil, isEditMode: false)
        }
        self.postingUseCase = postingUseCase
        self.locationService = locationService // DI로 받음
        locationService.delegate = self
    }
    
    func handle(_ intent: PostingIntent) {
        
        switch intent {
        case .initialRequest:
            Task {
                await loadInitialData()
            }
        case .editPost(let postId, let posting):
            Task {
                await editPost(postId: postId, posting: posting)
            }
        case .deletePost(let postId):
            Task {
                await deletePost(postId: postId)
            }
        case .savePost(let posting):
            Task {
                await savePostWithDTO(posting: posting)
            }
        case .savePostWithData(let title, let content, let category, let selectedFiles):
            Task {
                await savePost(title: title, content: content, category: category, selectedFiles: selectedFiles)
            }
        case .validateFiles(let files):
            validateFilesAndUpdateModel(files: files)
        case .deleteExistingFile(let fileName):
            deleteExistingFile(fileName)
        case .checkLocationPermission:
            checkLocationPermission()
        case .retry:
            if let onRetry = model.onRetry {
                onRetry()
            }
        case .dismiss:
            if let onDismiss = model.onDismiss {
                onDismiss()
            }
        }
    }
    
    // MARK: - 게시글 관련 메서드들
    
    // 초기 데이터 로드
    private func loadInitialData() async {
        checkLocationPermission()
        
        // 수정 모드일 경우 기존 게시글 데이터 로드
        if model.isEditMode, let post = model.post {
            // 기존 데이터는 이미 model에 설정되어 있음
            // 필요시 추가 데이터 로드 로직
        }
    }
    
    // 위치 권한 확인
    private func checkLocationPermission() {
        let status = locationService.authorizationStatus
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:

            model.hasLocationPermission = true
            model.locationPermissionDenied = false
        case .denied, .restricted:

            model.hasLocationPermission = false
            model.locationPermissionDenied = true
        case .notDetermined:

            locationService.requestLocationPermission()
        @unknown default:

            model.hasLocationPermission = false
            model.locationPermissionDenied = true
        }
    }
    
    // 기존 파일 삭제
    private func deleteExistingFile(_ fileName: String) {
        if let index = model.existingFiles.firstIndex(of: fileName) {
            model.existingFiles.remove(at: index)
            model.deletedFiles.append(fileName)
        }
    }
    
    // 게시글 수정
    func editPost(postId: String, posting: EditPostRequestDTO) async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            let response = try await postingUseCase.editPost(postId: postId, posting: posting)
            // 성공 시 PostDetailContainer에 수정된 게시글 정보 전송
            NotificationCenter.default.post(name: .postUpdated, object: response)
            // 성공 시 toast 표시
            model.toast = FancyToast(
                type: .success,
                title: "성공",
                message: "게시글이 수정되었습니다.",
                duration: 2.0
            )
            // 1.2초 후 pop
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                // pop 로직은 View에서 처리
            }
        } catch {
            // 실패 시 alert 표시
            model.errorMessage = error.localizedDescription
            model.showErrorAlert = true
            model.onRetry = {
                Task {
                    await self.editPost(postId: postId, posting: posting)
                }
            }
            model.onDismiss = {
                // pop 로직은 View에서 처리
            }
        }
    }
    
    // 게시글 삭제
    private func deletePost(postId: String) async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            let result = try await postingUseCase.deletePost(postId: postId)
            if result {
                // 성공 시 toast 표시
                model.toast = FancyToast(
                    type: .success,
                    title: "성공",
                    message: "게시글이 삭제되었습니다.",
                    duration: 2.0
                )
                // 1.2초 후 pop
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    // pop 로직은 View에서 처리
                }
            } else {
                // 실패 시 alert 표시
                model.errorMessage = "삭제에 실패했습니다."
                model.showErrorAlert = true
                model.onRetry = {
                    Task {
                        await self.deletePost(postId: postId)
                    }
                }
                model.onDismiss = {
                    // pop 로직은 View에서 처리
                }
            }
        } catch {
            // 실패 시 alert 표시
            model.errorMessage = error.localizedDescription
            model.showErrorAlert = true
            model.onRetry = {
                Task {
                    await self.deletePost(postId: postId)
                }
            }
            model.onDismiss = {
                // pop 로직은 View에서 처리
            }
        }
    }
    
    // 게시글 저장 (DTO 사용)
    private func savePostWithDTO(posting: PostRequestDTO) async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            // 1. 현재 위치 획득
            let location = await getCurrentLocation()
            let longitude = location?.coordinate.longitude ?? 0.0
            let latitude = location?.coordinate.latitude ?? 0.0
            
            // 2. 파일 업로드 (있는 경우)
            var uploadedFiles: [String] = []
            if !posting.files.isEmpty {
                // 파일 업로드 로직은 별도로 구현 필요
                // 현재는 posting.files를 그대로 사용
                uploadedFiles = posting.files
            }
            
            // 3. PostRequestDTO 생성 및 저장
            let updatedDto = PostRequestDTO(
                category: posting.category,
                title: posting.title,
                content: posting.content,
                longitude: longitude,
                latitude: latitude,
                files: uploadedFiles
            )
            
            let response = try await postingUseCase.posting(dto: updatedDto)
            // 성공 시 toast 표시
            model.toast = FancyToast(
                type: .success,
                title: "성공",
                message: "게시글이 저장되었습니다.",
                duration: 2.0
            )
            // 1.2초 후 pop
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                // pop 로직은 View에서 처리
            }
        } catch {
            // 실패 시 alert 표시
            model.errorMessage = error.localizedDescription
            model.showErrorAlert = true
            model.onRetry = {
                Task {
                    await self.savePostWithDTO(posting: posting)
                }
            }
            model.onDismiss = {
                // pop 로직은 View에서 처리
            }
        }
    }
    
    // 파일 검증 및 모델 업데이트
    private func validateFilesAndUpdateModel(files: [SelectedFile]) {
        let result = validateFiles(files)
        model.validFiles = result.valid
        model.invalidFileIndices = result.invalidIndices
        model.invalidFileReasons = result.invalidReasons
        model.hasDuplicateFile = result.hasDuplicate
    }
    
    // 파일 유효성 검사 (확장자, 용량, 개수, 중복)
    func validateFiles(_ files: [SelectedFile]) -> (valid: [SelectedFile], invalidIndices: Set<Int>, invalidReasons: [Int: String], hasDuplicate: Bool) {
        let allowedExtensions = FileUploadType.community.allowedExtensions
        let maxFileSize = FileUploadType.community.maxFileSize
        let maxFileCount = FileUploadType.community.maxFileCount
        
        var invalidIndices: Set<Int> = []
        var invalidReasons: [Int: String] = [:]
        var hasDuplicate = false
        
        // 1단계: 파일명 기반 중복 검사
        let fileNames = files.map { $0.fileName }
        let uniqueFileNames = Set(fileNames)
        if fileNames.count != uniqueFileNames.count {
            hasDuplicate = true
            print("⚠️ 파일명 중복 감지")
        }
        
        // 2단계: 파일 내용 샘플링 기반 해시 중복 검사 (파일명이 다른 경우)
        if !hasDuplicate {
            var fileHashes: [String] = []
            
            for file in files {
                let sampleData = sampleFileData(file, sampleSize: 1024) // 1KB 샘플링
                let hash = calculateFileHash(data: sampleData)
                fileHashes.append(hash)
            }
            
            let uniqueHashes = Set(fileHashes)
            if fileHashes.count != uniqueHashes.count {
                hasDuplicate = true
                print("⚠️ 파일 내용 중복 감지 (샘플링 해시 기반)")
            }
        }
        
        // 개수 제한
        let limitedFiles = Array(files.prefix(maxFileCount))
        
        for (index, file) in limitedFiles.enumerated() {
            let fileData = file.data ?? file.image?.jpegData(compressionQuality: 0.8) ?? Data()
            let fileExtension = file.fileExtension.lowercased()
            let isSizeValid = fileData.count <= maxFileSize
            let isExtensionValid = allowedExtensions.contains(fileExtension)
            
            if !isSizeValid || !isExtensionValid {
                invalidIndices.insert(index)
                var reasons: [String] = []
                if !isSizeValid {
                    let formatter = ByteCountFormatter()
                    formatter.allowedUnits = [.useKB, .useMB]
                    formatter.countStyle = .file
                    let fileSizeString = formatter.string(fromByteCount: Int64(fileData.count))
                    let maxSizeString = formatter.string(fromByteCount: Int64(maxFileSize))
                    reasons.append("크기: \(fileSizeString) (제한: \(maxSizeString))")
                }
                if !isExtensionValid {
                    reasons.append("확장자: \(fileExtension.uppercased()) (지원: \(allowedExtensions.joined(separator: ", ").uppercased()))")
                }
                invalidReasons[index] = reasons.joined(separator: ", ")
            }
        }
        
        let validFiles = limitedFiles.enumerated().filter { !invalidIndices.contains($0.offset) }.map { $0.element }
        return (valid: validFiles, invalidIndices: invalidIndices, invalidReasons: invalidReasons, hasDuplicate: hasDuplicate)
    }
    
    // 파일 데이터 샘플링 (성능 최적화)
    private func sampleFileData(_ file: SelectedFile, sampleSize: Int = 1024) -> Data {
        let fullData = file.data ?? file.image?.jpegData(compressionQuality: 0.8) ?? Data()
        
        // 파일 크기가 작으면 전체 사용
        if fullData.count <= sampleSize {
            return fullData
        }
        
        // 대용량 파일의 경우 스마트 샘플링
        var sampleData = Data()
        
        // 1. 파일 시작 부분 (헤더 정보) - 40%
        let headerSize = sampleSize * 4 / 10
        sampleData.append(fullData.prefix(headerSize))
        
        // 2. 파일 중간 부분 (데이터 영역) - 30%
        let middleSize = sampleSize * 3 / 10
        let middleStart = fullData.count / 2 - middleSize / 2
        let middleEnd = fullData.count / 2 + middleSize / 2
        if middleStart >= 0 && middleEnd <= fullData.count {
            sampleData.append(fullData[middleStart..<middleEnd])
        }
        
        // 3. 파일 끝 부분 (푸터 정보) - 30%
        let footerSize = sampleSize - sampleData.count
        if footerSize > 0 {
            sampleData.append(fullData.suffix(footerSize))
        }
        
        print("📊 파일 샘플링: \(file.fileName) - 전체: \(fullData.count) bytes → 샘플: \(sampleData.count) bytes")
        return sampleData
    }
    
    // 파일 내용 해시 계산
    private func calculateFileHash(data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // 파일 업로드: SelectedFile -> FileData 변환 후 업로드, 서버 경로([String]) 반환
    func fileUpload(selectedFiles: [SelectedFile]) async throws -> [String] {
        // SelectedFile을 FileData로 변환
        let fileDatas: [FileData] = selectedFiles.compactMap { selectedFile in
            if let image = selectedFile.image {
                // 이미지인 경우
                return FileManageHelper.shared.convertUIImage(image, fileName: selectedFile.fileName, uploadType: .community)
            } else if let data = selectedFile.data {
                // 데이터인 경우 (PDF 등)
                return FileManageHelper.shared.convertData(data, fileName: selectedFile.fileName, uploadType: .community)
            }
            return nil
        }
        
        // 파일 업로드
        let serverFiles = try await postingUseCase.uploadFiles(files: fileDatas)
        return serverFiles.map{$0.path}
    }
    
    // 게시글 저장 (위치 획득, 파일 업로드, 저장)
    func savePost(title: String, content: String, category: String, selectedFiles: [SelectedFile]) async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            // 1. 위치 권한 확인
            if !model.hasLocationPermission {
                model.errorMessage = "위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요."
                model.showErrorAlert = true
                return
            }
            
            // 2. 파일 유효성 검사
            let result = validateFiles(selectedFiles)
            if !result.invalidIndices.isEmpty || result.hasDuplicate {
                if result.hasDuplicate {
                    model.toast = FancyToast(type: .warning, title: "중복 파일", message: "중복된 파일이 포함되어 있습니다.", duration: 3)
                } else {
                    let names = result.invalidIndices.compactMap { idx in selectedFiles.indices.contains(idx) ? selectedFiles[idx].fileName : nil }
                    model.toast = FancyToast(type: .error, title: "파일 오류", message: "유효하지 않은 파일: \(names.joined(separator: ", "))", duration: 4)
                }
                return
            }
            
            // 3. 현재 위치 획득
            let location = await getCurrentLocation()
            guard let location = location else {
                model.errorMessage = "위치 정보를 가져올 수 없습니다. 위치 권한을 확인해주세요."
                model.showErrorAlert = true
                return
            }
            
            let longitude = location.coordinate.longitude
            let latitude = location.coordinate.latitude
            
            // 4. 파일 업로드 (있는 경우)
            var uploadedFiles: [String] = []
            if !selectedFiles.isEmpty {
                uploadedFiles = try await fileUpload(selectedFiles: selectedFiles)
            }
            
            // 5. 수정 모드인 경우 기존 파일 처리
            if model.isEditMode {
                // 삭제되지 않은 기존 파일들 추가
                let remainingFiles = model.existingFiles.filter { !model.deletedFiles.contains($0) }
                uploadedFiles.append(contentsOf: remainingFiles)
            }
            
            // 6. PostRequestDTO 생성 및 저장
            if model.isEditMode {
                // 수정 모드
                let editDto = EditPostRequestDTO(
                    category: category,
                    title: title,
                    content: content,
                    latitude: latitude,
                    longitude: longitude,
                    files: uploadedFiles
                )
                let response = try await postingUseCase.editPost(postId: model.postId, posting: editDto)
                model.toast = FancyToast(
                    type: .success,
                    title: "성공",
                    message: "게시글이 수정되었습니다.",
                    duration: 2.0
                )
            } else {
                // 신규 작성 모드
                let dto = PostRequestDTO(
                    category: category,
                    title: title,
                    content: content,
                    longitude: longitude,
                    latitude: latitude,
                    files: uploadedFiles
                )
                let response = try await postingUseCase.posting(dto: dto)
                model.toast = FancyToast(
                    type: .success,
                    title: "성공",
                    message: "게시글이 저장되었습니다.",
                    duration: 2.0
                )
            }
            
            // 1.2초 후 pop
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                // pop 로직은 View에서 처리
            }
            
        } catch {
            // 실패 시 alert 표시
            model.errorMessage = error.localizedDescription
            model.showErrorAlert = true
            model.onRetry = {
                Task {
                    await self.savePost(title: title, content: content, category: category, selectedFiles: selectedFiles)
                }
            }
            model.onDismiss = {
                // pop 로직은 View에서 처리
            }
        }
    }
    
    // 위치 비동기 획득 (권한 처리 포함)
    private func getCurrentLocation() async -> CLLocation? {
        
        if let coordinate = await locationService.requestCurrentLocation() {

            updateCurrentAddress(coordinate: coordinate)
            return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        } else {
            print("위치 획득 실패")
            return nil
        }
    }
    
    private func updateCurrentAddress(coordinate: CLLocationCoordinate2D) {
        Task {
            let address = await AddressMappingHelper.getSingleAddress(
                longitude: coordinate.longitude,
                latitude: coordinate.latitude
            )
            await MainActor.run {
                self.currentAddress = address
            }
        }
    }
    
    // MARK: - LocationServiceDelegate
    func locationService(didUpdateLocation coordinate: CLLocationCoordinate2D) {

        model.hasLocationPermission = true
        model.locationPermissionDenied = false
        updateCurrentAddress(coordinate: coordinate)
    }
    func locationService(didFailWithError error: Error) {

        model.hasLocationPermission = false
        model.locationPermissionDenied = true
    }
    func locationService(didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            model.hasLocationPermission = true
            model.locationPermissionDenied = false
        case .denied, .restricted:
            model.hasLocationPermission = false
            model.locationPermissionDenied = true
        case .notDetermined:
            // 권한 요청 중이므로 대기
            break
        @unknown default:
            model.hasLocationPermission = false
            model.locationPermissionDenied = true
        }
    }
}
