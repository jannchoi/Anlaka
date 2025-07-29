import SwiftUI
import PDFKit

struct PDFViewer: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PDFViewerViewModel.shared
    
    var body: some View {
        NavigationView {
            PDFKitView(pdfURL: viewModel.pdfURL)
                .navigationTitle("PDF Viewer")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .onAppear {
            // 외부에서 설정된 pdfPath를 사용
            if let pdfPath = viewModel.pdfPath {
                viewModel.loadPDF(from: pdfPath)
            }
        }
    }
}

// MARK: - PDFViewerViewModel
class PDFViewerViewModel: ObservableObject {
    @Published var pdfURL: URL?
    
    // 싱글톤 인스턴스로 pdfPath를 외부에서 설정할 수 있도록 함
    static let shared = PDFViewerViewModel()
    var pdfPath: String?
    
    private init() {}
    
    func setPDFPath(_ path: String) {
        self.pdfPath = path
        // pdfPath가 설정되면 즉시 로드 시작
        loadPDF(from: path)
    }
    
    func loadPDF(from pdfPath: String) {
        Task {
            let url = await downloadPDF(from: pdfPath)
            await MainActor.run {
                self.pdfURL = url
            }
        }
    }
    
    private func downloadPDF(from pdfPath: String) async -> URL? {
        // BaseURL과 결합하여 전체 URL 생성
        let fullURLString = BaseURL.baseV1 + pdfPath
        guard let url = URL(string: fullURLString) else {
            print("❌ [PDFViewer] 유효하지 않은 URL: \(fullURLString)")
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
                print("❌ [PDFViewer] HTTP 오류: \(response)")
                return nil
            }
            
            // 임시 파일로 저장
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
            try data.write(to: tempURL)
            
            print("✅ [PDFViewer] PDF 다운로드 완료: \(tempURL)")
            return tempURL
        } catch {
            print("❌ [PDFViewer] PDF 다운로드 실패: \(error)")
            return nil
        }
    }
}

struct PDFKitView: UIViewControllerRepresentable {
    let pdfURL: URL?
    
    func makeUIViewController(context: Context) -> PDFViewController {
        return PDFViewController(pdfURL: pdfURL)
    }
    
    func updateUIViewController(_ uiViewController: PDFViewController, context: Context) {
        // URL이 변경되었을 때 PDF를 다시 로드
        if uiViewController.pdfURL != pdfURL {
            uiViewController.updatePDF(with: pdfURL)
        }
    }
}

class PDFViewController: UIViewController {
    private var pdfView: PDFView!
    var pdfURL: URL? // internal로 변경하여 외부에서 접근 가능하게 함
    
    private var pageInfoContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 6
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.alpha = 0
        return view
    }()
    
    private var currentPageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.white
        label.textAlignment = .center
        return label
    }()
    
    private var timer: Timer?
    
    init(pdfURL: URL?) {
        self.pdfURL = pdfURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPDFView()
        setupUI()
        loadPDF()
        setupNotifications()
    }
    
    private func setupPDFView() {
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        view.addSubview(pdfView)
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupUI() {
        view.addSubview(pageInfoContainer)
        pageInfoContainer.addSubview(currentPageLabel)
        
        NSLayoutConstraint.activate([
            pageInfoContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            pageInfoContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            currentPageLabel.topAnchor.constraint(equalTo: pageInfoContainer.topAnchor, constant: 8),
            currentPageLabel.leadingAnchor.constraint(equalTo: pageInfoContainer.leadingAnchor, constant: 12),
            currentPageLabel.trailingAnchor.constraint(equalTo: pageInfoContainer.trailingAnchor, constant: -12),
            currentPageLabel.bottomAnchor.constraint(equalTo: pageInfoContainer.bottomAnchor, constant: -8),
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePageChange),
            name: .PDFViewPageChanged,
            object: pdfView
        )
    }
    
    private func loadPDF() {
        guard let pdfURL = pdfURL else { 
            print("⚠️ [PDFViewController] PDF URL이 nil입니다")
            return 
        }
        
        print("📄 [PDFViewController] PDF 로드 시도: \(pdfURL)")
        
        if let document = PDFDocument(url: pdfURL) {
            pdfView.document = document
            print("✅ [PDFViewController] PDF 로드 성공")
            
            // 첫 페이지 정보 표시
            if let currentPage = pdfView.currentPage {
                let pageIndex = document.index(for: currentPage)
                currentPageLabel.text = "\(pageIndex + 1) of \(document.pageCount)"
            }
        } else {
            print("❌ [PDFViewController] PDF 문서 로드 실패")
        }
    }
    
    // 외부에서 URL 업데이트를 위한 메서드
    func updatePDF(with url: URL?) {
        self.pdfURL = url
        loadPDF()
    }
    
    @objc
    private func handlePageChange() {
        guard let currentPage = pdfView.currentPage,
              let document = pdfView.document else {
            return
        }
        
        let pageIndex = document.index(for: currentPage)
        currentPageLabel.text = "\(pageIndex + 1) of \(document.pageCount)"
        
        UIView.animate(withDuration: 0.3, animations: {
            self.pageInfoContainer.alpha = 1
        }) { _ in
            self.startTimer()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            UIView.animate(withDuration: 0.5) {
                self.pageInfoContainer.alpha = 0
            }
        }
    }
} 