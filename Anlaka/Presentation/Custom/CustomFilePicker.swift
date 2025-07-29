import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct CustomFilePicker: View {
    @Binding var selectedFiles: [SelectedFile]
    let pickerType: FilePickerType
    @Environment(\.dismiss) private var dismiss
    
    // 기존 선택된 파일들의 파일명 (선택 상태 표시용)
    private var existingFileNames: Set<String> {
        Set(selectedFiles.map { $0.fileName })
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 선택된 파일 목록 표시
                if !selectedFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("선택된 파일 (\(selectedFiles.count)개)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(selectedFiles.indices, id: \.self) { index in
                                    CustomSelectedFileView(
                                        file: selectedFiles[index],
                                        onRemove: {
                                            selectedFiles.remove(at: index)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                // 파일 선택 옵션들
                VStack(spacing: 16) {
                    // 갤러리에서 선택
                    Button(action: {
                        // PhotosPicker 또는 기존 FilePicker 호출
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("갤러리에서 선택")
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // 파일에서 선택
                    Button(action: {
                        // DocumentPicker 호출
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("파일에서 선택")
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("파일 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 선택된 파일 표시 뷰
struct CustomSelectedFileView: View {
    let file: SelectedFile
    let onRemove: () -> Void
    
    var body: some View {
        VStack {
            // 파일 타입별 아이콘
            Group {
                switch file.fileType {
                case .image:
                    if let image = file.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "photo")
                            .font(.title2)
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                case .video:
                    Image(systemName: "video")
                        .font(.title2)
                        .frame(width: 60, height: 60)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                case .pdf:
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .frame(width: 60, height: 60)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // 파일명
            Text(file.fileName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
            
            // 삭제 버튼
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}


