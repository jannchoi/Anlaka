import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFiles: [SelectedFile]
    var pickerType: FilePickerType
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // 최대 선택 개수 설정 (기존 파일 개수를 고려하여 동적으로 계산)
        let remainingSlots = max(0, pickerType.selectionLimit - selectedFiles.count)
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: pickerType.allowedUTTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = remainingSlots > 1
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // 기존 파일들의 파일명 목록 (중복 검사용)
            let existingFileNames = Set(parent.selectedFiles.map { $0.fileName })
            var hasDuplicate = false
            var validFiles: [SelectedFile] = []
            let maxAllowedFiles = parent.pickerType.selectionLimit - parent.selectedFiles.count
            
            for (index, url) in urls.enumerated() {
                // 제한 개수 초과 시 중단
                if validFiles.count >= maxAllowedFiles {
                    break
                }
                
                let fileName = url.lastPathComponent
                let ext = url.pathExtension.lowercased()
                
                // 중복 검사
                if existingFileNames.contains(fileName) {
                    hasDuplicate = true
                    continue
                }
                
                // 파일 타입별 처리
                switch parent.pickerType {
                case .profile:
                    // 프로필: 이미지만 허용
                    if parent.pickerType.allowedImageExtensions.contains(ext) {
                        if let image = UIImage(contentsOfFile: url.path) {
                            let selectedFile = SelectedFile(
                                fileName: fileName,
                                fileType: .image,
                                image: image,
                                data: nil
                            )
                            validFiles.append(selectedFile)
                        }
                    }
                    
                case .chat:
                    // 채팅: 이미지 + PDF
                    if parent.pickerType.allowedImageExtensions.contains(ext) {
                        if let image = UIImage(contentsOfFile: url.path) {
                            let selectedFile = SelectedFile(
                                fileName: fileName,
                                fileType: .image,
                                image: image,
                                data: nil
                            )
                            validFiles.append(selectedFile)
                        }
                    } else if ext == "pdf" {
                        if let pdfData = try? Data(contentsOf: url) {
                            let selectedFile = SelectedFile(
                                fileName: fileName,
                                fileType: .pdf,
                                image: nil,
                                data: pdfData
                            )
                            validFiles.append(selectedFile)
                        }
                    }
                    
                case .community:
                    // 커뮤니티: 이미지 + 비디오
                    if parent.pickerType.allowedImageExtensions.contains(ext) {
                        if let image = UIImage(contentsOfFile: url.path) {
                            let selectedFile = SelectedFile(
                                fileName: fileName,
                                fileType: .image,
                                image: image,
                                data: nil
                            )
                            validFiles.append(selectedFile)
                        }
                    } else if parent.pickerType.allowedVideoExtensions.contains(ext) {
                        if let videoData = try? Data(contentsOf: url) {
                            let selectedFile = SelectedFile(
                                fileName: fileName,
                                fileType: .video,
                                image: nil,
                                data: videoData
                            )
                            validFiles.append(selectedFile)
                        }
                    }
                }
            }
            
            // 유효한 파일들을 한 번에 추가
            DispatchQueue.main.async {
                self.parent.selectedFiles.append(contentsOf: validFiles)
            }
            
            // 중복 파일이 감지된 경우 로그만 출력 (토스트는 컨테이너에서 처리)
            if hasDuplicate {
                print("⚠️ 중복된 파일이 감지되었습니다")
            }
        }
    }
} 