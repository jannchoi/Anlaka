import SwiftUI
import PhotosUI

struct PostingView: View {
    // MARK: - State
    @StateObject private var container: PostingContainer
    @Binding var path: NavigationPath
    let di: DIContainer

    // UI 상태
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: TextResource.Community.Category = .info
    @State private var showCategoryPicker: Bool = false
    @State private var selectedFiles: [SelectedFile] = []
    @State private var showFilePicker: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var isShowingImagePicker: Bool = false
    @State private var isShowingDocumentPicker: Bool = false
    @State private var showWarning: Bool = false
    @State private var warningMessage: String = ""
    @State private var toast: FancyToast? = nil
    @State private var invalidFileIndices: Set<Int> = []
    @State private var invalidFileReasons: [Int: String] = [:]
    @State private var hasDuplicateFile: Bool = false

    // 파일 용량/개수 제한
    private let maxFileCount = 5
    private let maxTotalSizeMB: Double = 5.0

    // 신규 작성/수정 통합 초기화
    init(post: PostResponseEntity? = nil, di: DIContainer, path: Binding<NavigationPath>) {
        self._container = StateObject(wrappedValue: di.makePostingContainer(post: post))
        self._path = path
        self.di = di
        // 수정 모드일 경우 기존 데이터로 초기화
        if let post = post {
            self._title = State(initialValue: post.title)
            self._content = State(initialValue: post.content)
            if let category = TextResource.Community.Category(rawValue: post.category) {
                self._selectedCategory = State(initialValue: category)
            }
        }
    }

    // 파일 총 용량 계산
    private var totalFileSizeMB: Double {
        selectedFiles.reduce(0) { $0 + $1.sizeMB }
    }
    
    // 총 파일 개수 계산 (새로 추가된 파일 + 기존 파일 - 삭제된 파일)
    private var totalFiles: Int {
        let existingFilesCount = container.model.isEditMode ? container.model.existingFiles.count - container.model.deletedFiles.count : 0
        return selectedFiles.count + existingFilesCount
    }

    // 저장 버튼 활성화 조건
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCategory != nil &&
        totalFiles <= maxFileCount &&
        totalFileSizeMB <= maxTotalSizeMB &&
        container.model.hasLocationPermission
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Custom Navigation Bar
            CustomNavigationBar(
                title: "게시글 작성하기",
                leftButton: {
                    Button(action: { 
                        if !path.isEmpty {
                            path.removeLast()
                        }
                    }) {
                        Image("chevron")
                            .font(.headline)
                            .foregroundColor(.MainTextColor)
                    }
                    .disabled(container.isSaving)
                },
                rightButton: {
                    Button(action: savePost) {
                        if container.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("저장하기")
                                .font(.soyoSubheadline)
                                .foregroundColor(.oliveMist)
                        }
                    }
                    .disabled(container.isSaving || !canSave)
                }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - 위치 권한 경고
                    if container.model.locationPermissionDenied {
                        LocationPermissionWarningView()
                    }
                    
                    // MARK: - 날짜/카테고리
                    HStack(spacing: 12) {
                        DateTextView(date: Date(), address: container.currentAddress)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
                        Spacer()
                        CategoryTextView(category: selectedCategory)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
                        categorySelectButton
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
                    }
                    // MARK: - 제목
                    PostingSectionTitleView(title: "제목")
                    GrowingTextField(text: $title, placeholder: "제목을 입력해주세요", font: .soyoBody, placeholderFont: .pretendardCaption, placeholderColor: .gray60)
                        .disabled(container.isSaving || !container.model.hasLocationPermission)
                    // MARK: - 내용
                    PostingSectionTitleView(title: "내용")
                    GrowingTextField(text: $content, placeholder: "내용을 입력해주세요", font: .soyoBody, placeholderFont: .pretendardCaption, placeholderColor: .gray60, minHeight: 120)
                        .disabled(container.isSaving || !container.model.hasLocationPermission)
                    // MARK: - 파일
                    HStack(spacing: 8) {
                        PostingSectionTitleView(title: "파일")
                        fileButton.disabled(container.isSaving || !container.model.hasLocationPermission)
                        photoButton.disabled(container.isSaving || !container.model.hasLocationPermission)
                        if showWarning {
                            Text(warningMessage)
                                .font(.pretendardCaption3)
                                .foregroundColor(.tomatoRed)
                        }
                    }
                    
                    // MARK: - 파일 선택 안내 및 개수 표시
                    HStack {
                        if selectedFiles.isEmpty && !container.model.isEditMode {
                            Text("파일을 선택하세요 (최대 \(maxFileCount)개)")
                                .font(.pretendardCaption)
                                .foregroundColor(.gray)
                        } else if selectedFiles.isEmpty && container.model.isEditMode {
                            Text("기존 파일: \(container.model.existingFiles.count - container.model.deletedFiles.count)개 (최대 \(maxFileCount)개)")
                                .font(.pretendardCaption)
                                .foregroundColor(.gray)
                        } else {
                            let currentTotal = totalFiles
                            Text("\(currentTotal)/\(maxFileCount)개 선택됨")
                                .font(.pretendardCaption)
                                .foregroundColor(currentTotal >= maxFileCount ? .tomatoRed : .gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    
                    // MARK: - 선택된 파일 목록
                    ForEach(selectedFiles.indices, id: \ .self) { idx in
                        SelectedFileView(file: selectedFiles[idx].toPostingViewModel(), onDelete: { deleteFile(at: idx) }, isInvalid: invalidFileIndices.contains(idx), invalidReason: invalidFileReasons[idx])
                            .disabled(container.isSaving || !container.model.hasLocationPermission)
                    }
                    
                    // MARK: - 기존 파일 목록 (수정 모드)
                    if container.model.isEditMode {
                        ForEach(container.model.existingFiles, id: \.self) { fileName in
                            ExistingFileView(
                                fileName: fileName,
                                onDelete: {
                                    container.handle(.deleteExistingFile(fileName))
                                }
                            )
                            .disabled(container.isSaving || !container.model.hasLocationPermission)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.warmLinen)
            .disabled(container.isSaving || !container.model.hasLocationPermission)
        }
        .background(Color.warmLinen.ignoresSafeArea())
        // MARK: - 파일/사진 피커 Sheet
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPicker(selectedFiles: $selectedFiles, pickerType: .community)
                .onChange(of: selectedFiles) { files in
                    handleFileSelection(files)
                }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            FilePicker(selectedFiles: $selectedFiles, pickerType: .community)
                .onChange(of: selectedFiles) { files in
                    handleFileSelection(files)
                }
        }
        .overlay(
            Group {
                if container.isSaving {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("저장 중...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        )
        .toastView(toast: $toast)
        .onChange(of: container.model.toast) { newToast in
            if let newToast = newToast {
                toast = newToast
                container.model.toast = nil
            }
        }
        .alert("오류", isPresented: $container.model.showErrorAlert) {
            Button("재시도") {
                container.handle(.retry)
            }
            Button("취소") {
                container.handle(.dismiss)
            }
        } message: {
            Text(container.model.errorMessage)
        }
        .onChange(of: container.model.toast) { newToast in
            if let newToast = newToast {
                // toast 표시 후 1.2초 뒤 pop
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    if !path.isEmpty {
                        path.removeLast()
                    }
                }
            }
        }
        .onAppear {
            // 초기 데이터 로드
            container.handle(.initialRequest)
            // 위치 권한 확인
            container.handle(.checkLocationPermission)
        }
    }

    // MARK: - 카테고리 선택 버튼
    private var categorySelectButton: some View {
        Menu {
            ForEach(TextResource.Community.Category.allCases, id: \ .self) { category in
                Button(category.displayName) {
                    selectedCategory = category
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("카테고리")
                    .font(.soyoSubheadline)
                Image(systemName: "arrow.down")
            }
            .foregroundColor(.gray75)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
        }
        .font(.soyoSubheadline)
        .disabled(false)
    }

    // MARK: - 파일 버튼
    private var fileButton: some View {
        Button(action: {
            if totalFiles < maxFileCount && totalFileSizeMB < maxTotalSizeMB {
                isShowingDocumentPicker = true
            } else {
                showWarning = true
                warningMessage = "최대 5개, 5MB 이하만 첨부 가능"
            }
        }) {
            Image(systemName: "paperclip")
                .frame(width: 18, height: 18)
                .foregroundColor(totalFiles < maxFileCount && totalFileSizeMB < maxTotalSizeMB ? .MainTextColor : .gray60)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
        }
        .disabled(totalFiles >= maxFileCount || totalFileSizeMB >= maxTotalSizeMB)
    }

    // MARK: - 사진 버튼
    private var photoButton: some View {
        Button(action: {
            if totalFiles < maxFileCount && totalFileSizeMB < maxTotalSizeMB {
                isShowingImagePicker = true
            } else {
                showWarning = true
                warningMessage = "최대 5개, 5MB 이하만 첨부 가능"
            }
        }) {
            Image(systemName: "photo")
                .frame(width: 18, height: 18)
                .foregroundColor(totalFiles < maxFileCount && totalFileSizeMB < maxTotalSizeMB ? .MainTextColor : .gray60)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
        }
        .disabled(totalFiles >= maxFileCount || totalFileSizeMB >= maxTotalSizeMB)
    }

    // MARK: - 파일 삭제
    private func deleteFile(at index: Int) {
        selectedFiles.remove(at: index)
        showWarning = false
    }

    // 파일/사진 선택 시 유효성 검증 및 경고
    private func handleFileSelection(_ files: [SelectedFile]) {
        container.handle(.validateFiles(files: files))
        selectedFiles = files
        invalidFileIndices = container.model.invalidFileIndices
        invalidFileReasons = container.model.invalidFileReasons
        hasDuplicateFile = container.model.hasDuplicateFile
        if hasDuplicateFile {
            toast = FancyToast(type: .warning, title: "중복 파일", message: "중복된 파일이 포함되어 있습니다.", duration: 3)
        } else if !invalidFileIndices.isEmpty {
            let names = invalidFileIndices.compactMap { idx in files.indices.contains(idx) ? files[idx].fileName : nil }
            toast = FancyToast(type: .error, title: "파일 오류", message: "유효하지 않은 파일: \(names.joined(separator: ", "))", duration: 4)
        }
    }

    // 저장 시 최종 검증
    private func savePost() {
        guard canSave else { return }
        container.handle(.savePostWithData(
            title: title,
            content: content,
            category: selectedCategory.rawValue,
            selectedFiles: selectedFiles
        ))
    }
}

// MARK: - Custom Components

struct DateTextView: View {
    let date: Date
    let address: String
    var body: some View {
        HStack(spacing: 4) {
            Text(dateFormatter.string(from: date))
            if !address.isEmpty {
                Text(address)
            }
        }
        .font(.soyoSubheadline)
        .foregroundColor(.MainTextColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
    }
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy.MM.dd"
        return df
    }
}

struct CategoryTextView: View {
    let category: TextResource.Community.Category
    var body: some View {
        Text(category.displayName)
            .font(.pretendardFootnote)
            .foregroundColor(.MainTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
    }
}

struct PostingSectionTitleView: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.soyoBody)
            .foregroundColor(.MainTextColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
    }
}

struct GrowingTextField: View {
    @Binding var text: String
    let placeholder: String
    let font: Font
    let placeholderFont: Font
    let placeholderColor: Color
    var minHeight: CGFloat = 44
    @State private var dynamicHeight: CGFloat = 44
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(placeholderFont)
                    .foregroundColor(placeholderColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
            }
            TextEditor(text: $text)
                .font(font)
                .frame(minHeight: dynamicHeight, maxHeight: .infinity)
                .background(Color.white)
                .cornerRadius(3)
                .onAppear {
                    dynamicHeight = minHeight
                }
        }
        .frame(minHeight: minHeight)
        .background(Color.white)
        .cornerRadius(3)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.gray75, lineWidth: 0.5)
        )
    }
}


struct SelectedFileView: View {
    let file: PostingSelectedFileViewModel
    let onDelete: () -> Void
    var isInvalid: Bool = false
    var invalidReason: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(file.name)
                    .font(.pretendardCaption)
                    .foregroundColor(.MainTextColor)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundColor(isInvalid ? .tomatoRed : .gray75)
                }
            }
            if let reason = invalidReason, isInvalid {
                Text(reason)
                    .font(.pretendardCaption3)
                    .foregroundColor(.tomatoRed)
            }
            Text(String(format: "%.1fmb", file.sizeMB))
                .font(.pretendardCaption3)
                .foregroundColor(.gray75)
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(3)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(isInvalid ? Color.tomatoRed : Color.gray75, lineWidth: 1.5)
        )
    }
}

struct ExistingFileView: View {
    let fileName: String
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(fileName)
                    .font(.pretendardCaption)
                    .foregroundColor(.MainTextColor)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundColor(.gray75)
                }
            }
            Text("기존 파일")
                .font(.pretendardCaption3)
                .foregroundColor(.gray75)
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(3)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.gray75, lineWidth: 1.5)
        )
    }
}

struct LocationPermissionWarningView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.slash.fill")
                    .foregroundColor(.tomatoRed)
                Text("위치 권한 필요")
                    .font(.pretendardSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.tomatoRed)
            }
            Text("게시글 작성에는 위치 정보가 필요합니다. 설정에서 위치 권한을 허용해주세요.")
                .font(.pretendardCaption)
                .foregroundColor(.gray75)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(Color.tomatoRed.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.tomatoRed.opacity(0.3), lineWidth: 1)
        )
    }
}

