import SwiftUI
import AVKit

struct VideoViewer: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VideoViewerViewModel.shared
    
    var body: some View {
        ZStack {
            // 배경색
            Color.black.ignoresSafeArea()
            
            if let player = viewModel.player {
                // 비디오 플레이어
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.toggleControls()
                    }
                
                // 컨트롤 오버레이
                if viewModel.showControls {
                    VStack {
                        // 상단 컨트롤 (뒤로가기 버튼)
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        // 중앙 재생/일시정지 버튼
                        Button(action: {
                            viewModel.togglePlayPause()
                        }) {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .shadow(radius: 3)
                        }
                        
                        Spacer()
                        
                        // 하단 컨트롤 (진행률, 시간)
                        VStack(spacing: 12) {
                            // 진행률 슬라이더
                            Slider(
                                value: Binding(
                                    get: { viewModel.currentTime },
                                    set: { newValue in
                                        viewModel.currentTime = newValue
                                        if !viewModel.isSeeking {
                                            player.seek(to: CMTime(seconds: newValue, preferredTimescale: 600))
                                        }
                                    }
                                ),
                                in: 0...max(viewModel.duration, 1)
                            )
                            .accentColor(.white)
                            .onAppear {
                                // 슬라이더 드래그 시작
                                let slider = UISlider()
                                slider.addTarget(viewModel, action: #selector(VideoViewerViewModel.sliderTouchDown), for: .touchDown)
                                slider.addTarget(viewModel, action: #selector(VideoViewerViewModel.sliderTouchUp), for: [.touchUpInside, .touchUpOutside])
                            }
                            
                            // 시간 표시
                            HStack {
                                Text(viewModel.formatTime(viewModel.currentTime))
                                    .font(.pretendardCaption)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text(viewModel.formatTime(viewModel.duration))
                                    .font(.pretendardCaption)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.7),
                                Color.clear,
                                Color.clear,
                                Color.black.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            } else {
                // 로딩 또는 오류 상태
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("비디오를 불러오는 중...")
                        .font(.pretendardBody)
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // setVideoURL에서 이미 setupPlayer를 호출하므로 여기서는 불필요
        }
        .onDisappear {
            viewModel.cleanupPlayer()
        }
    }
}

// MARK: - VideoViewerViewModel
class VideoViewerViewModel: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isSeeking = false
    @Published var showControls = true
    @Published var videoURL: String?
    
    // 싱글톤 인스턴스로 videoURL을 외부에서 설정할 수 있도록 함
    static let shared = VideoViewerViewModel()
    
    private var timeObserver: Any?
    private var controlsTimer: Timer?
    
    private override init() {
        super.init()
    }
    
    func setVideoURL(_ url: String) {

        self.videoURL = url
        // URL 설정 후 플레이어 설정
        setupPlayer(videoURL: url)

    }
    
    func setupPlayer(videoURL: String) {

        Task {
            let authenticatedURL = await downloadVideoWithAuth(videoURL: videoURL)
            
            await MainActor.run {
                if let url = authenticatedURL {

                    self.player = AVPlayer(url: url)
                    
                    // 시간 관찰자 추가 (안전한 방법)
                    let interval = CMTime(seconds: 0.5, preferredTimescale: 600) // 30fps 기준
                    self.timeObserver = self.player?.addPeriodicTimeObserver(
                        forInterval: interval,
                        queue: .main
                    ) { [weak self] time in
                        guard let self = self else { return }
                        if !self.isSeeking {
                            self.currentTime = time.seconds
                        }
                    }
                    
                    // 재생 상태 관찰자 추가
                    self.player?.addObserver(self, forKeyPath: "rate", options: [.new], context: nil)
                    
                    // 비디오 로드 완료 시 duration 설정
                    let asset = AVAsset(url: url)
                    asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
                        DispatchQueue.main.async {
                            self?.duration = asset.duration.seconds
                        }
                    }
                }
            }
        }
    }
    
    private func downloadVideoWithAuth(videoURL: String) async -> URL? {
        // BaseURL과 결합하여 전체 URL 생성
        let fullURLString = BaseURL.baseV1 + videoURL
        
        guard let url = URL(string: fullURLString) else {
            print("❌ [VideoViewer] 유효하지 않은 URL: \(fullURLString)")
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
                print("❌ [VideoViewer] HTTP 오류: \(response)")
                return nil
            }
            
            // 원본 파일 확장자에 따라 임시 파일 생성
            let fileExtension = URL(string: videoURL)?.pathExtension.lowercased() ?? "mp4"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "." + fileExtension)
            try data.write(to: tempURL)
            
            return tempURL
        } catch {
            print("❌ [VideoViewer] 비디오 다운로드 실패: \(error)")
            return nil
        }
    }
    
    func cleanupPlayer() {
        player?.pause()
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        player?.removeObserver(self, forKeyPath: "rate")
        player = nil
        controlsTimer?.invalidate()
        controlsTimer = nil
    }
    
    // MARK: - Controls
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
        resetControlsTimer()
    }
    
    func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        resetControlsTimer()
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.showControls = false
                }
            }
        }
    }
    
    // MARK: - Slider Controls
    @objc func sliderTouchDown() {
        isSeeking = true
    }
    
    @objc func sliderTouchUp() {
        isSeeking = false
        player?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
    }
    
    // MARK: - Time Formatting
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - KVO Observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = self?.player?.rate != 0
            }
        }
    }
}

#Preview {
    VideoViewer()
} 