import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

enum FilePickerType {
    case profile
    case chat
    case community
    
    var selectionLimit: Int {
        switch self {
        case .profile: return 1
        case .chat, .community: return 5
        }
    }
    
    var filter: PHPickerFilter {
        switch self {
        case .profile:
            return .images
        case .chat:
            // 이미지 + PDF
            return PHPickerFilter.any(of: [.images, .livePhotos])
        case .community:
            // 이미지 + 비디오
            return PHPickerFilter.any(of: [.images, .videos])
        }
    }
    
    var allowedImageExtensions: [String] {
        switch self {
        case .profile: return ["jpg", "jpeg", "png"]
        case .chat: return ["jpg", "jpeg", "png", "gif"]
        case .community: return ["jpg", "jpeg", "png", "gif", "webp"]
        }
    }
    var allowedVideoExtensions: [String] {
        switch self {
        case .community: return ["mp4", "mov", "avi", "mkv", "wmv"]
        default: return []
        }
    }
    var allowPDF: Bool {
        self == .chat
    }
    
    // DocumentPicker에서 사용할 UTType 배열
    var allowedUTTypes: [UTType] {
        switch self {
        case .profile:
            return [.jpeg, .png]
        case .chat:
            return [.jpeg, .png, .gif, .pdf]
        case .community:
            return [.jpeg, .png, .gif, .movie, .video]
        }
    }
}

struct FilePicker: UIViewControllerRepresentable {
    @Binding var selectedFiles: [SelectedFile]
    var pickerType: FilePickerType
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        // 최대 선택 개수 설정 (기존 파일 개수를 고려하여 동적으로 계산)
        let remainingSlots = max(0, pickerType.selectionLimit - selectedFiles.count)
        config.selectionLimit = remainingSlots
        config.filter = pickerType.filter
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: FilePicker
        init(_ parent: FilePicker) { self.parent = parent }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            // 기존 파일들의 파일명 목록 (중복 검사용)
            let existingFileNames = Set(parent.selectedFiles.map { $0.fileName })
            var hasDuplicate = false
            
            for result in results {
                // 이미지
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        if let image = image as? UIImage {
                            result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.image") { url, error in
                                let fileName = url?.lastPathComponent ?? "image.jpg"
                                let ext = (fileName as NSString).pathExtension.lowercased()
                                
                                // 확장자가 없는 경우 UTType으로 정확한 확장자 자동 추가
                                let finalFileName: String
                                if ext.isEmpty {
                                    // UTType으로 정확한 파일 타입 감지
                                    var detectedExtension = "jpg" // 기본값
                                    
                                    if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.png.identifier) {
                                        detectedExtension = "png"
                                    } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) {
                                        detectedExtension = "gif"
                                    } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.webP.identifier) {
                                        detectedExtension = "webp"
                                    }
                                    
                                    // 확장자 추가
                                    let baseName = (fileName as NSString).deletingPathExtension
                                    finalFileName = "\(baseName).\(detectedExtension)"
                                    print("🔄 [FilePicker] 확장자 자동 추가: \(fileName) -> \(finalFileName)")
                                } else {
                                    // 확장자가 있지만 허용되지 않는 경우 업로드 거부
                                    if !(self?.parent.pickerType.allowedImageExtensions.contains(ext) == true) {
                                        print("❌ [FilePicker] 지원하지 않는 이미지 확장자: \(ext)")
                                        return
                                    }
                                    finalFileName = fileName
                                }
                                // 중복 검사
                                if existingFileNames.contains(fileName) {
                                    hasDuplicate = true
                                }
                                
                                let selectedFile = SelectedFile(
                                    fileName: finalFileName,
                                    fileType: .image,
                                    image: image,
                                    data: nil
                                )
                                DispatchQueue.main.async {
                                    self?.parent.selectedFiles.append(selectedFile)
                                }
                            }
                        }
                    }
                }
                // 비디오 (커뮤니티만)
                else if parent.pickerType.allowedVideoExtensions.count > 0,
                        result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                        if let url = url {
                            let ext = url.pathExtension.lowercased()
                            let fileName = url.lastPathComponent
                            
                            // 확장자가 없는 경우 UTType으로 정확한 확장자 자동 추가
                            let finalFileName: String
                            if ext.isEmpty {
                                // iOS 갤러리 비디오는 대부분 MOV
                                let baseName = (fileName as NSString).deletingPathExtension
                                finalFileName = "\(baseName).mov"
                                print("🔄 [FilePicker] 비디오 확장자 자동 추가: \(fileName) -> \(finalFileName)")
                            } else {
                                // 확장자가 있지만 허용되지 않는 경우 업로드 거부
                                guard let self = self else { return }
                                if !self.parent.pickerType.allowedVideoExtensions.contains(ext) {
                                    print("❌ [FilePicker] 지원하지 않는 비디오 확장자: \(ext)")
                                    print("🔍 [FilePicker] 허용된 확장자: \(self.parent.pickerType.allowedVideoExtensions)")
                                    return
                                }
                                finalFileName = fileName
                            }
                            // 중복 검사
                            if existingFileNames.contains(url.lastPathComponent) {
                                hasDuplicate = true
                            }
                            
                            // 비디오 파일을 Data로 로드
                            if let videoData = try? Data(contentsOf: url) {
                                let selectedFile = SelectedFile(
                                    fileName: finalFileName,
                                    fileType: .video,
                                    image: nil,
                                    data: videoData
                                )
                                DispatchQueue.main.async {
                                    self?.parent.selectedFiles.append(selectedFile)
                                }
                            }
                        }
                    }
                }
                // PDF (채팅만)
                else if parent.pickerType.allowPDF,
                        result.itemProvider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { [weak self] url, error in
                        if let url = url {
                            let ext = url.pathExtension.lowercased()
                            if ext == "pdf" {
                                // 중복 검사
                                if existingFileNames.contains(url.lastPathComponent) {
                                    hasDuplicate = true
                                }
                                
                                // PDF 파일을 Data로 로드
                                if let pdfData = try? Data(contentsOf: url) {
                                    let selectedFile = SelectedFile(
                                        fileName: url.lastPathComponent,
                                        fileType: .pdf,
                                        image: nil,
                                        data: pdfData
                                    )
                                    DispatchQueue.main.async {
                                        self?.parent.selectedFiles.append(selectedFile)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // 중복 파일이 감지된 경우 로그만 출력 (토스트는 컨테이너에서 처리)
            if hasDuplicate {
                print("⚠️ 중복된 파일이 감지되었습니다")
            }
        }
    }
}
